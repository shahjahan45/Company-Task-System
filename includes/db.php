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
    try {
        $pdo=db();
        $q=$pdo->query("SHOW TABLES LIKE 'users'");
        if(!$q->fetchColumn()) return false;
        $q=$pdo->query("SELECT COUNT(*) FROM users u JOIN user_roles ur ON ur.user_id=u.id JOIN roles r ON r.id=ur.role_id WHERE r.slug='super_admin' AND u.account_status='active'");
        return (int)$q->fetchColumn()>0;
    } catch(Throwable){ return false; }
}
function schema_ready(): bool { try{$q=db()->query("SHOW TABLES LIKE 'users'");return (bool)$q->fetchColumn();}catch(Throwable){return false;} }
function transaction(callable $fn): mixed { $pdo=db();$pdo->beginTransaction();try{$r=$fn($pdo);$pdo->commit();return $r;}catch(Throwable $e){if($pdo->inTransaction())$pdo->rollBack();throw $e;} }


function ensure_runtime_schema(): void {
    static $done=false;
    if($done)return;
    $done=true;
    try{
        $pdo=db();
        $pdo->exec("CREATE TABLE IF NOT EXISTS daily_growth_counts (
          id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
          activity_date DATE NOT NULL UNIQUE,
          customers_registered INT UNSIGNED NOT NULL DEFAULT 0,
          drivers_registered INT UNSIGNED NOT NULL DEFAULT 0,
          created_by BIGINT UNSIGNED NULL,
          updated_by BIGINT UNSIGNED NULL,
          created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          INDEX idx_growth_date(activity_date),
          CONSTRAINT fk_growth_created_by FOREIGN KEY(created_by) REFERENCES users(id) ON DELETE SET NULL,
          CONSTRAINT fk_growth_updated_by FOREIGN KEY(updated_by) REFERENCES users(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
        $count=(int)$pdo->query("SELECT COUNT(*) FROM daily_growth_counts")->fetchColumn();
        if($count===0){
            $pdo->exec("INSERT INTO daily_growth_counts(activity_date,customers_registered,drivers_registered)
              SELECT DATE(registration_at),0,COUNT(*) FROM drivers WHERE verification_status='verified' GROUP BY DATE(registration_at)
              ON DUPLICATE KEY UPDATE drivers_registered=VALUES(drivers_registered)");
        }
    }catch(Throwable){}
}

function growth_count_summary(?DateTimeImmutable $now=null): array {
    ensure_runtime_schema();
    $tz=new DateTimeZone((string)setting('business_timezone',config('app.timezone','Asia/Qatar')));
    $now=$now?$now->setTimezone($tz):new DateTimeImmutable('now',$tz);
    $today=$now->format('Y-m-d');
    $yesterday=$now->modify('-1 day')->format('Y-m-d');
    $pdo=db();
    $q=$pdo->prepare("SELECT activity_date,customers_registered,drivers_registered FROM daily_growth_counts WHERE activity_date IN (?,?)");
    $q->execute([$today,$yesterday]);
    $by=[];foreach($q->fetchAll() as $r)$by[$r['activity_date']]=$r;
    $total=$pdo->query("SELECT COALESCE(SUM(customers_registered),0) customers,COALESCE(SUM(drivers_registered),0) drivers FROM daily_growth_counts")->fetch();
    $week=$pdo->prepare("SELECT COALESCE(SUM(customers_registered),0) customers,COALESCE(SUM(drivers_registered),0) drivers FROM daily_growth_counts WHERE activity_date BETWEEN ? AND ?");
    $week->execute([$now->modify('-6 days')->format('Y-m-d'),$today]);$weekRow=$week->fetch();
    return [
      'today_date'=>$today,'yesterday_date'=>$yesterday,
      'today_customers'=>(int)($by[$today]['customers_registered']??0),'today_drivers'=>(int)($by[$today]['drivers_registered']??0),
      'yesterday_customers'=>(int)($by[$yesterday]['customers_registered']??0),'yesterday_drivers'=>(int)($by[$yesterday]['drivers_registered']??0),
      'total_customers'=>(int)($total['customers']??0),'total_drivers'=>(int)($total['drivers']??0),
      'week_customers'=>(int)($weekRow['customers']??0),'week_drivers'=>(int)($weekRow['drivers']??0),
    ];
}
