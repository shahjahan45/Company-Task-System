<?php
require dirname(__DIR__).'/includes/bootstrap.php';require_permission('campaigns.manage');verify_csrf();
$id=(int)($_POST['id']??0);$name=trim((string)($_POST['name']??''));$start=(string)($_POST['start_date']??'');$deadline=(string)($_POST['deadline']??'');$target=max(1,(int)($_POST['target_count']??1));$status=(string)($_POST['status']??'active');
if(!$id||$name===''||!strtotime($start)||!strtotime($deadline)||strtotime($deadline)<strtotime($start)||!in_array($status,['draft','active','completed','cancelled'],true)){flash('error','Invalid campaign update.');redirect('campaigns.php');}
$pdo=db();$q=$pdo->prepare('SELECT name,target_count,start_date,deadline,status FROM campaigns WHERE id=?');$q->execute([$id]);$old=$q->fetch();if(!$old){flash('error','Campaign not found.');redirect('campaigns.php');}
$manager=(int)($_POST['manager_employee_id']??0)?:null;$notes=trim((string)($_POST['notes']??''));
$pdo->prepare('UPDATE campaigns SET name=?,start_date=?,deadline=?,target_count=?,manager_employee_id=?,status=?,notes=?,updated_by=? WHERE id=?')->execute([$name,$start,$deadline,$target,$manager,$status,$notes?:null,current_user_id(),$id]);
audit('campaign.updated','campaign',$id,['before'=>$old,'after'=>['name'=>$name,'target_count'=>$target,'start_date'=>$start,'deadline'=>$deadline,'status'=>$status]]);flash('success','Campaign updated and dashboard metrics recalculated.');redirect('campaigns.php');
