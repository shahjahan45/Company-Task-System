<?php
require dirname(__DIR__).'/includes/bootstrap.php';
require_permission('tasks.create');
verify_csrf();

$title=trim((string)($_POST['title']??''));
$description=trim((string)($_POST['description']??''));
$assignmentMode=(string)($_POST['assignment_mode']??'single');
$singleAssignee=(int)($_POST['primary_assignee_id']??0);
$category=(int)($_POST['category_id']??0)?:null;
$priority=(string)($_POST['priority']??'medium');
$status=(string)($_POST['status']??'to_do');
$progress=max(0,min(100,(int)($_POST['progress']??0)));
$due=!empty($_POST['due_at'])?date('Y-m-d H:i:s',strtotime((string)$_POST['due_at'])):null;

$allowedPriority=['low','medium','high','urgent'];
$allowedStatuses=['backlog','to_do','in_progress','blocked','in_review','completed'];
if($title==='' || !in_array($priority,$allowedPriority,true) || !in_array($status,$allowedStatuses,true) || !in_array($assignmentMode,['single','all'],true)){
    flash('error','Enter valid task details.');
    redirect('tasks.php');
}
if($assignmentMode==='single' && !$singleAssignee){
    flash('error','Select an employee or choose Assign to all employees.');
    redirect('tasks.php');
}

try{
    $created=transaction(function(PDO $pdo)use($title,$description,$assignmentMode,$singleAssignee,$category,$priority,$status,$progress,$due){
        if($assignmentMode==='all'){
            $employeeIds=array_map('intval',$pdo->query("SELECT id FROM employees WHERE employment_status='active' ORDER BY id")->fetchAll(PDO::FETCH_COLUMN));
        }else{
            $q=$pdo->prepare("SELECT id FROM employees WHERE id=? AND employment_status='active'");
            $q->execute([$singleAssignee]);
            $employeeIds=$q->fetchColumn()?[$singleAssignee]:[];
        }
        if(!$employeeIds)throw new RuntimeException('No active employee is available for this assignment.');

        $insert=$pdo->prepare('INSERT INTO tasks(task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) VALUES(?,?,?,?,?,?,?,CURDATE(),?,?,?,?)');
        $assigneeInsert=$pdo->prepare('INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(?,?)');
        $activity=$pdo->prepare('INSERT INTO task_activity_logs(task_id,user_id,action,to_value) VALUES(?,? ,"created",?)');
        $userLookup=$pdo->prepare('SELECT user_id FROM employees WHERE id=?');
        $actualProgress=$status==='completed'?100:$progress;
        if($status==='in_review' && $actualProgress<80)$actualProgress=80;
        if($status==='in_progress' && $actualProgress===0)$actualProgress=25;
        $completedAt=$status==='completed'?gmdate('Y-m-d H:i:s'):null;
        $ids=[];
        foreach($employeeIds as $employeeId){
            $code='TSK-'.date('ymdHis').'-'.str_pad((string)$employeeId,3,'0',STR_PAD_LEFT).'-'.random_int(10,99);
            $insert->execute([$code,$title,$description!==''?$description:null,$category,$priority,current_user_id(),$employeeId,$due,$status,$actualProgress,$completedAt]);
            $id=(int)$pdo->lastInsertId();$ids[]=$id;
            $assigneeInsert->execute([$id,$employeeId]);
            $activity->execute([$id,current_user_id(),$status]);
            $userLookup->execute([$employeeId]);$uid=(int)$userLookup->fetchColumn();
            if($uid)create_notification($uid,'task_assignment','New task assigned',$code.' — '.$title,'assignment-'.$id,url('tasks.php'));
            audit('task.created','task',$id,['assignee'=>$employeeId,'assignment_mode'=>$assignmentMode,'status'=>$status]);
        }
        return count($ids);
    });
    flash('success',$created>1?$created.' individual task copies created — one for every active employee.':'Task created and employee notified.');
}catch(Throwable $e){
    flash('error',$e->getMessage()?:'Could not create the task.');
}
redirect('tasks.php');
