<?php
require dirname(__DIR__).'/includes/bootstrap.php';require_permission('drivers.edit');verify_csrf();
$id=(int)($_POST['id']??0);if(!$id)redirect('drivers.php');
try{transaction(function(PDO $pdo)use($id){$q=$pdo->prepare('SELECT driver_code,full_name FROM drivers WHERE id=? FOR UPDATE');$q->execute([$id]);$row=$q->fetch();if(!$row)throw new RuntimeException('Driver not found.');audit('driver.deleted','driver',$id,['driver_code'=>$row['driver_code'],'name'=>$row['full_name']]);$pdo->prepare('DELETE FROM drivers WHERE id=?')->execute([$id]);});flash('success','Driver deleted.');}catch(Throwable $e){flash('error','Could not delete driver.');}
redirect('drivers.php');
