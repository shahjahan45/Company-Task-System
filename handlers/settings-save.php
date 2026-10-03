<?php
require dirname(__DIR__).'/includes/bootstrap.php';require_permission('settings.manage');verify_csrf();
$textKeys=['company_name','business_timezone','dashboard_refresh_seconds','date_format','public_nav_subtitle','public_hero_badge','public_hero_title','public_hero_subtitle','public_notice','public_refresh_seconds','public_footer_text'];
$boolKeys=['public_dashboard_enabled','public_show_driver_growth','public_show_employee_performance','public_show_employee_tasks','public_show_operations','public_show_task_feed','public_show_team','public_show_campaigns','public_show_activity'];
$publicKeys=['company_name','business_timezone','public_nav_subtitle','public_hero_badge','public_hero_title','public_hero_subtitle','public_notice','public_refresh_seconds','public_footer_text','brand_logo_path',...$boolKeys];
$pdo=db();$changed=[];
try{
    if(isset($_POST['remove_brand_logo'])){
        $old=trim((string)setting('brand_logo_path',''));if($old!==''&&!str_contains($old,'..')){@unlink(PROJECT_ROOT.'/'.ltrim($old,'/'));}
        $pdo->prepare('INSERT INTO system_settings(setting_key,setting_value,is_public,updated_by) VALUES("brand_logo_path","",1,?) ON DUPLICATE KEY UPDATE setting_value="",is_public=1,updated_by=VALUES(updated_by)')->execute([current_user_id()]);$changed[]='brand_logo_path';
    }
    if(isset($_FILES['brand_logo'])&&($_FILES['brand_logo']['error']??UPLOAD_ERR_NO_FILE)!==UPLOAD_ERR_NO_FILE){
        $file=$_FILES['brand_logo'];if(($file['error']??UPLOAD_ERR_OK)!==UPLOAD_ERR_OK)throw new RuntimeException('Logo upload failed. Please choose the image again.');
        if((int)($file['size']??0)>2*1024*1024)throw new RuntimeException('Navbar logo must be 2 MB or smaller.');
        $tmp=(string)($file['tmp_name']??'');$finfo=new finfo(FILEINFO_MIME_TYPE);$mime=$finfo->file($tmp);$allowed=['image/png'=>'png','image/jpeg'=>'jpg','image/webp'=>'webp'];if(!isset($allowed[$mime]))throw new RuntimeException('Navbar logo must be PNG, JPG, or WebP.');
        if(@getimagesize($tmp)===false)throw new RuntimeException('The selected logo file is not a valid image.');
        $dir=PROJECT_ROOT.'/assets/uploads/branding';if(!is_dir($dir)&&!mkdir($dir,0775,true)&&!is_dir($dir))throw new RuntimeException('Could not create the branding upload folder.');
        foreach(glob($dir.'/nav-logo.*')?:[] as $oldFile)@unlink($oldFile);
        $name='nav-logo.'.$allowed[$mime];$target=$dir.'/'.$name;if(!move_uploaded_file($tmp,$target))throw new RuntimeException('Could not save the navbar logo. Check project folder permissions.');
        $relative='assets/uploads/branding/'.$name;$pdo->prepare('INSERT INTO system_settings(setting_key,setting_value,is_public,updated_by) VALUES("brand_logo_path",?,1,?) ON DUPLICATE KEY UPDATE setting_value=VALUES(setting_value),is_public=1,updated_by=VALUES(updated_by)')->execute([$relative,current_user_id()]);$changed[]='brand_logo_path';
    }
    foreach($textKeys as $key){if(!array_key_exists($key,$_POST))continue;$value=trim((string)$_POST[$key]);if(in_array($key,['dashboard_refresh_seconds','public_refresh_seconds'],true))$value=(string)max(10,min(300,(int)$value));$isPublic=in_array($key,$publicKeys,true)?1:0;$pdo->prepare('INSERT INTO system_settings(setting_key,setting_value,is_public,updated_by) VALUES(?,?,?,?) ON DUPLICATE KEY UPDATE setting_value=VALUES(setting_value),is_public=VALUES(is_public),updated_by=VALUES(updated_by)')->execute([$key,$value,$isPublic,current_user_id()]);$changed[]=$key;}
    $hasPublicForm=array_key_exists('public_hero_title',$_POST)||array_key_exists('public_refresh_seconds',$_POST)||isset($_FILES['brand_logo']);
    if($hasPublicForm){foreach($boolKeys as $key){$value=isset($_POST[$key])?'1':'0';$pdo->prepare("INSERT INTO system_settings(setting_key,setting_value,setting_type,is_public,updated_by) VALUES(?,?,'boolean',1,?) ON DUPLICATE KEY UPDATE setting_value=VALUES(setting_value),setting_type='boolean',is_public=1,updated_by=VALUES(updated_by)")->execute([$key,$value,current_user_id()]);$changed[]=$key;}}
    audit('settings.updated','system',null,['keys'=>array_values(array_unique($changed))]);flash('success','Settings saved. Public branding and dashboard visibility are updated.');
}catch(Throwable $e){flash('error',$e->getMessage());}
redirect('settings.php');
