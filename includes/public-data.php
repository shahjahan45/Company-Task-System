<?php
function public_bool(string $key, bool $default=true): bool {
    $raw=(string)setting($key,$default?'1':'0');
    return in_array(strtolower($raw),['1','true','yes','on'],true);
}

function public_dashboard_data(): array {
    $pdo=db();
    $campaign=$pdo->query("SELECT * FROM campaigns WHERE status='active' ORDER BY start_date DESC,id DESC LIMIT 1")->fetch();
    if(!$campaign)$campaign=['id'=>0,'name'=>'No active campaign','start_date'=>date('Y-m-d'),'deadline'=>date('Y-m-d'),'target_count'=>1,'timezone'=>setting('business_timezone',config('app.timezone','Asia/Qatar'))];
    $cid=(int)$campaign['id'];$counted=0;$today=0;
    if($cid){
        $q=$pdo->prepare('SELECT COUNT(*) FROM campaign_registrations WHERE campaign_id=? AND counted=1');$q->execute([$cid]);$counted=(int)$q->fetchColumn();
        $todayDate=(new DateTimeImmutable('now',new DateTimeZone((string)($campaign['timezone']??'Asia/Qatar'))))->format('Y-m-d');
        $q=$pdo->prepare('SELECT COUNT(*) FROM campaign_registrations WHERE campaign_id=? AND counted=1 AND DATE(counted_at)=?');$q->execute([$cid,$todayDate]);$today=(int)$q->fetchColumn();
    }
    $progress=campaign_progress($campaign,$counted,$today);
    $totalDrivers=(int)$pdo->query("SELECT COUNT(*) FROM drivers WHERE status<>'rejected'")->fetchColumn();
    $verifiedDrivers=(int)$pdo->query("SELECT COUNT(*) FROM drivers WHERE verification_status='verified'")->fetchColumn();
    $weekDrivers=(int)$pdo->query("SELECT COUNT(*) FROM drivers WHERE registration_at>=UTC_TIMESTAMP()-INTERVAL 7 DAY AND verification_status='verified'")->fetchColumn();
    $pending=(int)$pdo->query("SELECT COUNT(*) FROM tasks WHERE status NOT IN ('completed','cancelled')")->fetchColumn();
    $overdue=(int)$pdo->query("SELECT COUNT(*) FROM tasks WHERE status NOT IN ('completed','cancelled') AND due_at IS NOT NULL AND due_at<UTC_TIMESTAMP()")->fetchColumn();
    $completed=(int)$pdo->query("SELECT COUNT(*) FROM tasks WHERE status='completed'")->fetchColumn();
    $completedWeek=(int)$pdo->query("SELECT COUNT(*) FROM tasks WHERE status='completed' AND completed_at>=UTC_TIMESTAMP()-INTERVAL 7 DAY")->fetchColumn();
    $activeEmployees=(int)$pdo->query("SELECT COUNT(*) FROM employees WHERE employment_status='active'")->fetchColumn();
    $departments=$pdo->query("SELECT d.name,COUNT(e.id) c FROM departments d LEFT JOIN employees e ON e.department_id=d.id AND e.employment_status='active' GROUP BY d.id,d.name HAVING c>0 ORDER BY c DESC,d.name LIMIT 8")->fetchAll();
    $daily=$pdo->query("SELECT DATE(registration_at) d,COUNT(*) c FROM drivers WHERE verification_status='verified' AND registration_at>=UTC_TIMESTAMP()-INTERVAL 13 DAY GROUP BY DATE(registration_at) ORDER BY d")->fetchAll();
    $taskStatus=$pdo->query("SELECT status,COUNT(*) c FROM tasks GROUP BY status ORDER BY c DESC")->fetchAll();
    $campaigns=$pdo->query("SELECT id,name,start_date,deadline,target_count,status FROM campaigns ORDER BY CASE status WHEN 'active' THEN 0 ELSE 1 END,start_date DESC LIMIT 5")->fetchAll();
    $recentTasks=$pdo->query("SELECT t.id,t.task_code,t.title,t.status,t.priority,t.progress,t.due_at,e.full_name assignee,COALESCE(t.completed_at,t.updated_at) activity_at FROM tasks t LEFT JOIN employees e ON e.id=t.primary_assignee_id WHERE t.status<>'cancelled' ORDER BY COALESCE(t.completed_at,t.updated_at) DESC LIMIT 10")->fetchAll();
    $recentDrivers=$pdo->query("SELECT registration_at,verification_status,registration_source FROM drivers ORDER BY registration_at DESC LIMIT 8")->fetchAll();

    $assignmentSql="SELECT id task_id,primary_assignee_id employee_id FROM tasks WHERE primary_assignee_id IS NOT NULL UNION SELECT task_id,employee_id FROM task_assignees";
    $employeePerformance=$pdo->query("SELECT e.id,e.full_name,e.job_title,d.name department,
        COUNT(t.id) total_tasks,
        SUM(CASE WHEN t.status='completed' THEN 1 ELSE 0 END) completed_tasks,
        SUM(CASE WHEN t.status IN ('to_do','in_progress','blocked','in_review','backlog') THEN 1 ELSE 0 END) open_tasks,
        SUM(CASE WHEN t.status='in_progress' THEN 1 ELSE 0 END) in_progress_tasks,
        SUM(CASE WHEN t.status='in_review' THEN 1 ELSE 0 END) review_tasks,
        SUM(CASE WHEN t.status NOT IN ('completed','cancelled') AND t.due_at IS NOT NULL AND t.due_at<UTC_TIMESTAMP() THEN 1 ELSE 0 END) overdue_tasks,
        ROUND(COALESCE(AVG(CASE WHEN t.id IS NOT NULL THEN t.progress END),0),1) avg_progress
      FROM employees e
      LEFT JOIN departments d ON d.id=e.department_id
      LEFT JOIN ($assignmentSql) a ON a.employee_id=e.id
      LEFT JOIN tasks t ON t.id=a.task_id AND t.status<>'cancelled'
      WHERE e.employment_status='active'
      GROUP BY e.id,e.full_name,e.job_title,d.name
      ORDER BY completed_tasks DESC,total_tasks DESC,e.full_name")->fetchAll();
    foreach($employeePerformance as &$emp){
        $total=(int)$emp['total_tasks'];$done=(int)$emp['completed_tasks'];
        $emp['completion_percentage']=$total>0?round(($done/$total)*100,1):0.0;
        $emp['remaining_tasks']=max(0,$total-$done);
    } unset($emp);

    $employeeTasks=[];
    $taskRows=$pdo->query("SELECT a.employee_id,t.id,t.task_code,t.title,t.status,t.priority,t.progress,t.start_date,t.due_at,t.completed_at,c.name category
      FROM ($assignmentSql) a
      JOIN tasks t ON t.id=a.task_id AND t.status<>'cancelled'
      LEFT JOIN task_categories c ON c.id=t.category_id
      JOIN employees e ON e.id=a.employee_id AND e.employment_status='active'
      ORDER BY a.employee_id,CASE t.status WHEN 'in_progress' THEN 0 WHEN 'in_review' THEN 1 WHEN 'to_do' THEN 2 WHEN 'blocked' THEN 3 WHEN 'backlog' THEN 4 WHEN 'completed' THEN 5 ELSE 6 END,COALESCE(t.due_at,'2999-12-31'),t.updated_at DESC")->fetchAll();
    foreach($taskRows as $row)$employeeTasks[(int)$row['employee_id']][]=$row;

    $versions=[
        (string)$pdo->query("SELECT CONCAT(COUNT(*),':',COALESCE(MAX(UNIX_TIMESTAMP(updated_at)),0)) FROM tasks")->fetchColumn(),
        (string)$pdo->query("SELECT CONCAT(COUNT(*),':',COALESCE(MAX(UNIX_TIMESTAMP(updated_at)),0)) FROM drivers")->fetchColumn(),
        (string)$pdo->query("SELECT CONCAT(COUNT(*),':',COALESCE(MAX(UNIX_TIMESTAMP(updated_at)),0)) FROM employees")->fetchColumn(),
        (string)$pdo->query("SELECT CONCAT(COUNT(*),':',COALESCE(MAX(UNIX_TIMESTAMP(updated_at)),0)) FROM campaigns")->fetchColumn(),
        (string)$pdo->query("SELECT CONCAT(COUNT(*),':',COALESCE(MAX(UNIX_TIMESTAMP(updated_at)),0)) FROM system_settings")->fetchColumn(),
    ];
    $contentVersion=sha1(implode('|',$versions));

    return compact('campaign','progress','totalDrivers','verifiedDrivers','weekDrivers','pending','overdue','completed','completedWeek','activeEmployees','departments','daily','taskStatus','campaigns','recentTasks','recentDrivers','employeePerformance','employeeTasks','contentVersion');
}
