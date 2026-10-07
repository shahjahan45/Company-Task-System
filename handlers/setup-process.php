<?php
require dirname(__DIR__).'/includes/bootstrap.php';
if(installed()) redirect('login.php');
verify_csrf();
$name=trim((string)($_POST['name']??''));$email=strtolower(trim((string)($_POST['email']??'')));$password=(string)($_POST['password']??'');$confirm=(string)($_POST['password_confirmation']??'');
$cfg=['host'=>trim((string)($_POST['db_host']??'127.0.0.1')),'port'=>trim((string)($_POST['db_port']??'3306')),'database'=>trim((string)($_POST['db_database']??'idriver_command_center')),'username'=>trim((string)($_POST['db_username']??'root')),'password'=>(string)($_POST['db_password']??'')];
$_SESSION['_old']=['name'=>$name,'email'=>$email];$_SESSION['_setup_db']=$cfg;
if($name===''||!filter_var($email,FILTER_VALIDATE_EMAIL)||strlen($password)<12||$password!==$confirm){flash('error','Enter a name, valid email, matching passwords, and at least 12 password characters.');redirect('setup.php');}
if(!preg_match('/^[A-Za-z0-9_]+$/',$cfg['database'])){flash('error','Database name may contain only letters, numbers, and underscores.');redirect('setup.php');}
try{
    $server=db_server($cfg);
    $sql=file_get_contents(PROJECT_ROOT.'/database/idriver_command_center.sql'); if($sql===false)throw new RuntimeException('Database SQL file is missing.');
    $dbName=$cfg['database'];
    $sql=preg_replace('/CREATE DATABASE IF NOT EXISTS `idriver_command_center`/','CREATE DATABASE IF NOT EXISTS `'.$dbName.'`',$sql);
    $sql=str_replace('USE `idriver_command_center`','USE `'.$dbName.'`',$sql);
    $parts=preg_split('/;\s*(?:\r?\n|$)/',$sql);
    foreach($parts as $statement){$statement=trim($statement);if($statement===''||str_starts_with($statement,'--')){if(str_starts_with($statement,'--')&&str_contains($statement,"\n")){$statement=preg_replace('/^(?:--[^\n]*\n)+/','',$statement);$statement=trim((string)$statement);}else continue;}if($statement!=='')$server->exec($statement);}
    $local="<?php\nreturn ['db'=>[\n    'host'=>".var_export($cfg['host'],true).",\n    'port'=>".var_export($cfg['port'],true).",\n    'database'=>".var_export($dbName,true).",\n    'username'=>".var_export($cfg['username'],true).",\n    'password'=>".var_export($cfg['password'],true).",\n    'charset'=>'utf8mb4',\n]];\n";
    if(@file_put_contents(PROJECT_ROOT.'/config.local.php',$local)===false)throw new RuntimeException('Could not write config.local.php. Give the project folder write permission and retry.');
    $pdo=new PDO("mysql:host={$cfg['host']};port={$cfg['port']};dbname={$dbName};charset=utf8mb4",$cfg['username'],$cfg['password'],[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC]);
    $pdo->beginTransaction();
    $findUser=$pdo->prepare('SELECT id FROM users WHERE email=? LIMIT 1');
    $findUser->execute([$email]);
    $uid=(int)($findUser->fetchColumn()?:0);
    if($uid>0){
        $pdo->prepare('UPDATE users SET password_hash=?, account_status="active" WHERE id=?')->execute([password_hash($password,PASSWORD_DEFAULT),$uid]);
    }else{
        $pdo->prepare('INSERT INTO users(email,password_hash,account_status) VALUES(?,? ,"active")')->execute([$email,password_hash($password,PASSWORD_DEFAULT)]);
        $uid=(int)$pdo->lastInsertId();
    }
    $role=(int)$pdo->query("SELECT id FROM roles WHERE slug='super_admin' LIMIT 1")->fetchColumn();
    if(!$role) throw new RuntimeException('Super Administrator role is missing.');
    $pdo->prepare('INSERT IGNORE INTO user_roles(user_id,role_id) VALUES(?,?)')->execute([$uid,$role]);
    $dept=(int)$pdo->query("SELECT id FROM departments WHERE slug='management' LIMIT 1")->fetchColumn();
    $findEmployee=$pdo->prepare('SELECT id,employee_code FROM employees WHERE user_id=? OR work_email=? LIMIT 1');
    $findEmployee->execute([$uid,$email]);
    $existingEmployee=$findEmployee->fetch();
    if($existingEmployee){
        $eid=(int)$existingEmployee['id'];
        $pdo->prepare('UPDATE employees SET user_id=?,full_name=?,work_email=?,department_id=?,job_title="System Administrator",employment_status="active",joining_date=COALESCE(joining_date,CURDATE()) WHERE id=?')->execute([$uid,$name,$email,$dept?:null,$eid]);
    }else{
        $employeeCode=next_employee_code($pdo,$uid);
        $pdo->prepare('INSERT INTO employees(user_id,employee_code,full_name,work_email,department_id,job_title,employment_status,joining_date) VALUES(?,?,?,?,?,"System Administrator","active",CURDATE())')->execute([$uid,$employeeCode,$name,$email,$dept?:null]);
        $eid=(int)$pdo->lastInsertId();
    }
    $pdo->prepare('INSERT INTO audit_logs(user_id,action,entity_type,entity_id,metadata_json,ip_address,user_agent) VALUES(?,"system.installed","system",NULL,?, ?, ?)')->execute([$uid,json_encode(['architecture'=>'plain-php','version'=>'1.1','employee_id'=>$eid]),$_SERVER['REMOTE_ADDR']??null,substr((string)($_SERVER['HTTP_USER_AGENT']??''),0,500)]);
    $pdo->commit();
    clear_old();unset($_SESSION['_setup_db']);flash('success','Setup completed successfully. Sign in to manage the public dashboard and operations.');redirect('login.php');
}catch(Throwable $e){if(isset($pdo)&&$pdo instanceof PDO&&$pdo->inTransaction())$pdo->rollBack();flash('error','Setup could not finish: '.$e->getMessage());redirect('setup.php');}
