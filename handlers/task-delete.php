<?php
require dirname(__DIR__).'/includes/bootstrap.php';require_permission('tasks.edit');verify_csrf();
$id=(int)($_POST['id']??0);if(!$id)redirect('tasks.php');
try{transaction(function(PDO $pdo)use($id){$q=$pdo->prepare('SELECT task_code,title FROM tasks WHERE id=? FOR UPDATE');$q->execute([$id]);$row=$q->fetch();if(!$row)throw new RuntimeException('Task not found.');audit('task.deleted','task',$id,['task_code'=>$row['task_code'],'title'=>$row['title']]);$pdo->prepare('DELETE FROM tasks WHERE id=?')->execute([$id]);});flash('success','Task deleted.');}catch(Throwable $e){flash('error','Could not delete task.');}
redirect('tasks.php');
