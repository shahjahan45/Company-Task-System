<?php
require dirname(__DIR__).'/includes/bootstrap.php';require_permission('employees.manage');verify_csrf();
$id=(int)($_POST['id']??0);if(!$id)redirect('employees.php');
try{transaction(function(PDO $pdo)use($id){
    $q=$pdo->prepare('SELECT e.user_id,e.full_name,u.account_status,r.slug role_slug FROM employees e LEFT JOIN users u ON u.id=e.user_id LEFT JOIN user_roles ur ON ur.user_id=u.id LEFT JOIN roles r ON r.id=ur.role_id WHERE e.id=? FOR UPDATE');$q->execute([$id]);$row=$q->fetch();if(!$row)throw new RuntimeException('Employee not found.');
    if((int)$row['user_id']===current_user_id())throw new RuntimeException('You cannot delete your own employee account.');
    if($row['role_slug']==='super_admin'){$count=(int)$pdo->query("SELECT COUNT(DISTINCT u.id) FROM users u JOIN user_roles ur ON ur.user_id=u.id JOIN roles r ON r.id=ur.role_id WHERE r.slug='super_admin' AND u.account_status='active'")->fetchColumn();if($count<=1)throw new RuntimeException('The last Super Administrator cannot be deleted.');}
    $uid=(int)($row['user_id']??0);audit('employee.deleted','employee',$id,['name'=>$row['full_name']]);$pdo->prepare('DELETE FROM employees WHERE id=?')->execute([$id]);if($uid)$pdo->prepare('DELETE FROM users WHERE id=?')->execute([$uid]);
});flash('success','Employee deleted. Assigned records were safely unlinked.');}catch(Throwable $e){flash('error',$e->getMessage()?:'Could not delete employee.');}
redirect('employees.php');
