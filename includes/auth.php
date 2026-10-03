<?php
function current_user_id(): ?int { return isset($_SESSION['user_id'])?(int)$_SESSION['user_id']:null; }
function current_user(): ?array {
    static $cache=false;
    if($cache!==false)return $cache;
    $id=current_user_id(); if(!$id)return $cache=null;
    try{
        $q=db()->prepare('SELECT u.id,u.email,u.account_status,e.id employee_id,e.full_name,e.employee_code,r.name role_name,r.slug role_slug FROM users u LEFT JOIN employees e ON e.user_id=u.id LEFT JOIN user_roles ur ON ur.user_id=u.id LEFT JOIN roles r ON r.id=ur.role_id WHERE u.id=? LIMIT 1');$q->execute([$id]);$row=$q->fetch();
        if(!$row||$row['account_status']!=='active'){logout_user();return $cache=null;}return $cache=$row;
    }catch(Throwable){return $cache=null;}
}
function login_user(string $email,string $password): bool {
    $q=db()->prepare('SELECT id,password_hash,account_status FROM users WHERE email=? LIMIT 1');$q->execute([strtolower(trim($email))]);$u=$q->fetch();
    if(!$u||$u['account_status']!=='active'||!password_verify($password,$u['password_hash']))return false;
    session_regenerate_id(true);$_SESSION['user_id']=(int)$u['id'];db()->prepare('UPDATE users SET last_login_at=UTC_TIMESTAMP() WHERE id=?')->execute([$u['id']]);return true;
}
function logout_user(): void { unset($_SESSION['user_id']);session_regenerate_id(true); }
function require_auth(): void { if(!current_user_id()||!current_user())redirect('login.php'); }
function can(string $permission): bool {
    $u=current_user(); if(!$u)return false; if(($u['role_slug']??'')==='super_admin')return true;
    static $cache=[]; if(array_key_exists($permission,$cache))return $cache[$permission];
    $q=db()->prepare('SELECT COUNT(*) FROM role_permissions rp JOIN permissions p ON p.id=rp.permission_id JOIN user_roles ur ON ur.role_id=rp.role_id WHERE ur.user_id=? AND p.slug=?');$q->execute([$u['id'],$permission]);return $cache[$permission]=(bool)$q->fetchColumn();
}
function require_permission(string $permission): void { require_auth(); if(!can($permission)){http_response_code(403);include PROJECT_ROOT.'/403.php';exit;} }
