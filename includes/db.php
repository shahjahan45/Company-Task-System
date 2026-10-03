<?php
function db_server(array $override=[]): PDO {
    $host=$override['host']??config('db.host','127.0.0.1'); $port=$override['port']??config('db.port','3306');
    $user=$override['username']??config('db.username','root'); $pass=$override['password']??config('db.password','');
    return new PDO("mysql:host={$host};port={$port};charset=utf8mb4",$user,$pass,[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC,PDO::ATTR_EMULATE_PREPARES=>false]);
}
function db(): PDO {
    static $pdo;
    if($pdo instanceof PDO)return $pdo;
    $host=config('db.host','127.0.0.1');$port=config('db.port','3306');$name=config('db.database','idriver_command_center');$user=config('db.username','root');$pass=config('db.password','');$charset=config('db.charset','utf8mb4');
    $pdo=new PDO("mysql:host={$host};port={$port};dbname={$name};charset={$charset}",$user,$pass,[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC,PDO::ATTR_EMULATE_PREPARES=>false]);
    return $pdo;
}
function installed(): bool {
    try { $q=db()->query("SHOW TABLES LIKE 'users'"); if(!$q->fetchColumn())return false; $q=db()->query("SELECT COUNT(*) FROM users"); return (int)$q->fetchColumn()>0; } catch(Throwable){ return false; }
}
function schema_ready(): bool { try{$q=db()->query("SHOW TABLES LIKE 'users'");return (bool)$q->fetchColumn();}catch(Throwable){return false;} }
function transaction(callable $fn): mixed { $pdo=db();$pdo->beginTransaction();try{$r=$fn($pdo);$pdo->commit();return $r;}catch(Throwable $e){if($pdo->inTransaction())$pdo->rollBack();throw $e;} }
