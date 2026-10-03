<?php
require dirname(__DIR__).'/includes/bootstrap.php';require_permission('tasks.edit');verify_csrf();
$id=(int)($_POST['id']??0);$title=trim((string)($_POST['title']??''));$assignee=(int)($_POST['primary_assignee_id']??0);
$status=(string)($_POST['status']??'to_do');$progress=max(0,min(100,(int)($_POST['progress']??0)));$priority=(string)($_POST['priority']??'medium');
$allowedStatuses=['backlog','to_do','in_progress','blocked','in_review','completed','cancelled'];$allowedPriority=['low','medium','high','urgent'];
if(!$id||$title===''||!$assignee||!in_array($status,$allowedStatuses,true)||!in_array($priority,$allowedPriority,true)){flash('error','Enter valid task details.');redirect('tasks.php');}
try{transaction(function(PDO $pdo)use($id,$title,$assignee,$status,$progress,$priority){
    $q=$pdo->prepare('SELECT * FROM tasks WHERE id=? FOR UPDATE');$q->execute([$id]);$old=$q->fetch();if(!$old)throw new RuntimeException('Task not found.');
    if(!task_can_transition((string)$old['status'],$status) && !can('tasks.review'))throw new RuntimeException('That task status transition is not allowed.');
    $cat=(int)($_POST['category_id']??0)?:null;$due=!empty($_POST['due_at'])?date('Y-m-d H:i:s',strtotime((string)$_POST['due_at'])):null;$description=trim((string)($_POST['description']??''));
    $actual=$status==='completed'?100:$progress;$completed=$status==='completed'?($old['completed_at']?:gmdate('Y-m-d H:i:s')):null;
    $pdo->prepare('UPDATE tasks SET title=?,description=?,category_id=?,priority=?,primary_assignee_id=?,due_at=?,status=?,progress=?,completed_at=? WHERE id=?')->execute([$title,$description?:null,$cat,$priority,$assignee,$due,$status,$actual,$completed,$id]);
    $pdo->prepare('DELETE FROM task_assignees WHERE task_id=?')->execute([$id]);$pdo->prepare('INSERT INTO task_assignees(task_id,employee_id) VALUES(?,?)')->execute([$id,$assignee]);
    if($old['status']!==$status)$pdo->prepare('INSERT INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(?,? ,"status_changed",?,?)')->execute([$id,current_user_id(),$old['status'],$status]);
    else $pdo->prepare('INSERT INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(?,? ,"updated",NULL,?)')->execute([$id,current_user_id(),$title]);
    if((int)$old['primary_assignee_id']!==$assignee){$u=$pdo->prepare('SELECT user_id FROM employees WHERE id=?');$u->execute([$assignee]);$uid=(int)$u->fetchColumn();if($uid)create_notification($uid,'task_assignment','Task assigned to you',$old['task_code'].' — '.$title,'reassignment-'.$id.'-'.$assignee,url('tasks.php'));}
    audit('task.updated','task',$id,['status'=>$status,'progress'=>$actual,'assignee'=>$assignee]);
});flash('success','Task updated successfully.');}catch(Throwable $e){flash('error',$e->getMessage()?:'Could not update task.');}
redirect('tasks.php');
