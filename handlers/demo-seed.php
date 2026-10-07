<?php
require dirname(__DIR__).'/includes/bootstrap.php';require_permission('settings.manage');verify_csrf();
if((string)setting('demo_data_loaded','0')==='1'){flash('success','Demo data is already loaded: 6 sample employees, 45 driver registrations, and 30 tasks.');redirect('settings.php');}
try{
    $file=PROJECT_ROOT.'/database/demo_seed.sql';$sql=file_get_contents($file);if($sql===false)throw new RuntimeException('Demo seed file is missing.');
    $sql=preg_replace('/^\s*--.*$/m','',$sql);$parts=preg_split('/;\s*(?:\r?\n|$)/',$sql);
    transaction(function(PDO $pdo)use($parts){foreach($parts as $statement){$statement=trim((string)$statement);if($statement!=='')$pdo->exec($statement);}});
    audit('demo_data.loaded','system',null,['employees'=>6,'drivers'=>45,'tasks'=>30]);flash('success','Demo data loaded: 6 employees, 45 driver registrations, and 30 employee tasks.');
}catch(Throwable $e){flash('error','Could not load demo data: '.$e->getMessage());}
redirect('settings.php');
