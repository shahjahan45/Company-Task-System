<?php
require dirname(__DIR__).'/includes/bootstrap.php';require_permission('employees.manage');verify_csrf();
$id=(int)($_POST['id']??0);$name=trim((string)($_POST['full_name']??''));$email=strtolower(trim((string)($_POST['work_email']??'')));
if(!$id||$name===''||!filter_var($email,FILTER_VALIDATE_EMAIL)){flash('error','Enter a valid employee name and email.');redirect('employees.php');}
try{transaction(function(PDO $pdo)use($id,$name,$email){
    $q=$pdo->prepare('SELECT e.*,u.account_status,r.id current_role_id,r.slug current_role_slug FROM employees e LEFT JOIN users u ON u.id=e.user_id LEFT JOIN user_roles ur ON ur.user_id=u.id LEFT JOIN roles r ON r.id=ur.role_id WHERE e.id=? FOR UPDATE');$q->execute([$id]);$old=$q->fetch();if(!$old)throw new RuntimeException('Employee not found.');
    $dept=(int)($_POST['department_id']??0)?:null;$role=(int)($_POST['role_id']??0)?:null;if(($old['current_role_slug']??'')==='super_admin')$role=(int)$old['current_role_id'];$job=trim((string)($_POST['job_title']??''));$contact=trim((string)($_POST['contact_number']??''));$joining=$_POST['joining_date']?:null;
    $status=in_array($_POST['employment_status']??'',['active','inactive','on_leave'],true)?$_POST['employment_status']:'active';
    $pdo->prepare('UPDATE employees SET full_name=?,work_email=?,contact_number=?,department_id=?,job_title=?,employment_status=?,joining_date=? WHERE id=?')->execute([$name,$email,$contact?:null,$dept,$job?:null,$status,$joining,$id]);
    if($old['user_id']){
        $account=$status==='active'?'active':'inactive';
        if((int)$old['user_id']===current_user_id())$account='active';
        $pdo->prepare('UPDATE users SET email=?,account_status=? WHERE id=?')->execute([$email,$account,$old['user_id']]);
        if($role){$pdo->prepare('DELETE FROM user_roles WHERE user_id=?')->execute([$old['user_id']]);$pdo->prepare('INSERT INTO user_roles(user_id,role_id) VALUES(?,?)')->execute([$old['user_id'],$role]);}
    }
    audit('employee.updated','employee',$id,['email'=>$email,'status'=>$status]);
});flash('success','Employee updated successfully.');}catch(Throwable $e){flash('error',$e->getMessage()?:'Could not update employee. The email may already exist.');}
redirect('employees.php');
