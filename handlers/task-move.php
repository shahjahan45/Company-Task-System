<?php
require dirname(__DIR__).'/includes/bootstrap.php';
require_permission('tasks.edit');
verify_csrf();
header('Content-Type: application/json; charset=utf-8');

$id=(int)($_POST['id']??0);
$status=(string)($_POST['status']??'');
$allowed=['backlog','to_do','in_progress','blocked','in_review','completed'];
if(!$id || !in_array($status,$allowed,true)){
    http_response_code(422);
    echo json_encode(['ok'=>false,'message'=>'Invalid task or destination status.']);exit;
}

try{
    $result=transaction(function(PDO $pdo)use($id,$status){
        $q=$pdo->prepare('SELECT id,task_code,title,status,progress,completed_at FROM tasks WHERE id=? FOR UPDATE');
        $q->execute([$id]);$task=$q->fetch();
        if(!$task)throw new RuntimeException('Task not found.');
        $from=(string)$task['status'];
        if(!task_can_transition($from,$status))throw new RuntimeException('That task move is not allowed.');
        $progress=(int)$task['progress'];
        $completedAt=$task['completed_at'];
        if($status==='completed'){$progress=100;$completedAt=$completedAt?:gmdate('Y-m-d H:i:s');}
        elseif($status==='in_review'){$progress=max(80,min(95,$progress));$completedAt=null;}
        elseif($status==='in_progress'){$progress=$from==='completed'?90:max(25,min(95,$progress));$completedAt=null;}
        elseif($status==='to_do'){$progress=$from==='completed'?0:min(50,$progress);$completedAt=null;}
        elseif($status==='backlog'){$progress=0;$completedAt=null;}
        elseif($status==='blocked'){$progress=$from==='completed'?90:min(95,$progress);$completedAt=null;}
        $pdo->prepare('UPDATE tasks SET status=?,progress=?,completed_at=? WHERE id=?')->execute([$status,$progress,$completedAt,$id]);
        if($from!==$status)$pdo->prepare('INSERT INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(?,? ,"status_changed",?,?)')->execute([$id,current_user_id(),$from,$status]);
        audit('task.moved','task',$id,['from'=>$from,'to'=>$status,'progress'=>$progress]);
        return ['from'=>$from,'to'=>$status,'progress'=>$progress,'task_code'=>$task['task_code']];
    });
    echo json_encode(['ok'=>true,'message'=>'Task moved successfully.','data'=>$result]);
}catch(Throwable $e){
    http_response_code(422);
    echo json_encode(['ok'=>false,'message'=>$e->getMessage()?:'Could not move task.']);
}
