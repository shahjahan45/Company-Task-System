<?php
require dirname(__DIR__).'/includes/bootstrap.php';require_permission('campaigns.manage');verify_csrf();
$id=(int)($_POST['id']??0);if(!$id)redirect('campaigns.php');
try{transaction(function(PDO $pdo)use($id){$q=$pdo->prepare('SELECT name,status FROM campaigns WHERE id=? FOR UPDATE');$q->execute([$id]);$row=$q->fetch();if(!$row)throw new RuntimeException('Campaign not found.');audit('campaign.deleted','campaign',$id,['name'=>$row['name'],'status'=>$row['status']]);$pdo->prepare('DELETE FROM campaigns WHERE id=?')->execute([$id]);});flash('success','Campaign deleted.');}catch(Throwable $e){flash('error','Could not delete campaign.');}
redirect('campaigns.php');
