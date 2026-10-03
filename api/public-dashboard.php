<?php
require dirname(__DIR__).'/includes/bootstrap.php';
if(!installed())json_response(['ok'=>false,'message'=>'Not installed'],503);
require_once dirname(__DIR__).'/includes/public-data.php';
if(!public_bool('public_dashboard_enabled',true))json_response(['ok'=>false,'message'=>'Public dashboard disabled'],503);
$d=public_dashboard_data();
$employeePerformance=array_map(fn($e)=>[
    'id'=>(int)$e['id'],'total_tasks'=>(int)$e['total_tasks'],'completed_tasks'=>(int)$e['completed_tasks'],
    'completion_percentage'=>(float)$e['completion_percentage'],'avg_progress'=>(float)$e['avg_progress']
],$d['employeePerformance']);
json_response(['ok'=>true,'data'=>[
    'totalDrivers'=>$d['totalDrivers'],'verifiedDrivers'=>$d['verifiedDrivers'],'weekDrivers'=>$d['weekDrivers'],
    'pending'=>$d['pending'],'overdue'=>$d['overdue'],'completed'=>$d['completed'],'completedWeek'=>$d['completedWeek'],'activeEmployees'=>$d['activeEmployees'],
    'progress'=>$d['progress'],'employeePerformance'=>$employeePerformance,'contentVersion'=>$d['contentVersion'],
]]);
