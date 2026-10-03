<?php
require dirname(__DIR__).'/includes/bootstrap.php';
require_permission('drivers.edit');
verify_csrf();
$id=(int)($_POST['id']??0);
$name=trim((string)($_POST['full_name']??''));
$phone=trim((string)($_POST['phone']??''));
$normalized=preg_replace('/\D+/','',$phone)??'';
$status=(string)($_POST['status']??'verification_pending');
$allowed=['lead','registered','verification_pending','verified','rejected','inactive'];
if(!$id||$name===''||strlen($normalized)<7||!in_array($status,$allowed,true)){
    flash('error','Enter valid driver details.'); redirect('drivers.php');
}
if($status==='verified'&&!can('drivers.verify')){$status='verification_pending';}
$employee=(int)($_POST['assigned_employee_id']??0)?:null;
$source=trim((string)($_POST['registration_source']??''));
$notes=trim((string)($_POST['notes']??''));
try{
    transaction(function(PDO $pdo)use($id,$name,$phone,$normalized,$status,$employee,$source,$notes){
        $q=$pdo->prepare('SELECT * FROM drivers WHERE id=? FOR UPDATE');$q->execute([$id]);$old=$q->fetch();
        if(!$old)throw new RuntimeException('Driver not found.');
        $dupe=$pdo->prepare('SELECT id FROM drivers WHERE phone_normalized=? AND id<>? LIMIT 1');$dupe->execute([$normalized,$id]);
        if($dupe->fetchColumn())throw new RuntimeException('Another driver already uses this phone number.');
        $verification=$status==='verified'?'verified':($status==='rejected'?'rejected':'pending');
        $verifiedAt=$verification==='verified'?($old['verified_at']?:gmdate('Y-m-d H:i:s')):null;
        $pdo->prepare('UPDATE drivers SET full_name=?,phone=?,phone_normalized=?,status=?,registration_source=?,assigned_employee_id=?,verification_status=?,verified_at=?,notes=?,updated_by=? WHERE id=?')
            ->execute([$name,$phone,$normalized,$status,$source?:null,$employee,$verification,$verifiedAt,$notes?:null,current_user_id(),$id]);
        if($old['status']!==$status){
            $pdo->prepare('INSERT INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(?,?,?,?,?)')->execute([$id,$old['status'],$status,'Updated from driver CRUD',current_user_id()]);
        }
        $pdo->prepare('UPDATE campaign_registrations SET counted=?,counted_at=?,attribution_employee_id=?,registration_source=? WHERE driver_id=?')
            ->execute([$verification==='verified'?1:0,$verification==='verified'?($verifiedAt?:gmdate('Y-m-d H:i:s')):null,$employee,$source?:null,$id]);
        audit('driver.updated','driver',$id,['from_status'=>$old['status'],'to_status'=>$status]);
    });
    flash('success','Driver updated successfully.');
}catch(Throwable $e){flash('error',$e->getMessage()?:'Could not update driver.');}
redirect('drivers.php');
