<?php
function config(string $key, mixed $default = null): mixed {
    $value = $GLOBALS['IDRIVER_CONFIG'] ?? [];
    foreach (explode('.', $key) as $part) {
        if (!is_array($value) || !array_key_exists($part, $value)) return $default;
        $value = $value[$part];
    }
    return $value;
}

function e(mixed $value): string { return htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8'); }

function app_base_url(): string {
    static $base;
    if ($base !== null) return $base;
    $doc = realpath((string)($_SERVER['DOCUMENT_ROOT'] ?? '')) ?: '';
    $root = realpath(PROJECT_ROOT) ?: PROJECT_ROOT;
    $docN = str_replace('\\', '/', $doc);
    $rootN = str_replace('\\', '/', $root);
    if ($docN !== '' && str_starts_with(strtolower($rootN), strtolower($docN))) {
        $rel = substr($rootN, strlen($docN));
        $base = '/' . trim($rel, '/');
        if ($base === '/') $base = '';
        return $base;
    }
    $script = str_replace('\\','/', (string)($_SERVER['SCRIPT_NAME'] ?? ''));
    foreach (['/handlers/','/api/','/admin/','/auth/'] as $marker) {
        $pos = strpos($script, $marker);
        if ($pos !== false) { $base = substr($script, 0, $pos); return rtrim($base, '/'); }
    }
    $base = rtrim(dirname($script), '/.');
    return $base;
}

function url(string $path = ''): string {
    $base = app_base_url();
    return $base . ($path !== '' ? '/' . ltrim($path, '/') : '/');
}

function redirect(string $path): never { header('Location: ' . url($path)); exit; }
function redirect_raw(string $target): never { header('Location: ' . $target); exit; }

function csrf_token(): string { return (string)($_SESSION['_csrf'] ?? ''); }
function csrf_field(): string { return '<input type="hidden" name="_csrf" value="'.e(csrf_token()).'">'; }
function verify_csrf(): void {
    $token = (string)($_POST['_csrf'] ?? ($_SERVER['HTTP_X_CSRF_TOKEN'] ?? ''));
    if ($token === '' || !hash_equals(csrf_token(), $token)) {
        http_response_code(419); exit('Session expired or invalid request token. Please refresh and try again.');
    }
}

function flash(string $key, ?string $value = null): ?string {
    if ($value !== null) { $_SESSION['_flash'][$key] = $value; return null; }
    $v = $_SESSION['_flash'][$key] ?? null; unset($_SESSION['_flash'][$key]); return $v;
}
function old(string $key, string $default=''): string { return (string)($_SESSION['_old'][$key] ?? $default); }
function clear_old(): void { unset($_SESSION['_old']); }

function format_datetime(?string $value, string $format='d M Y, h:i A'): string {
    if (!$value) return '—';
    try {
        $dt = new DateTimeImmutable($value, new DateTimeZone('UTC'));
        return $dt->setTimezone(new DateTimeZone((string)config('app.timezone','Asia/Qatar')))->format($format);
    } catch (Throwable) { return $value; }
}

function setting(string $key, mixed $default=null): mixed {
    try {
        $q=db()->prepare('SELECT setting_value FROM system_settings WHERE setting_key=?');
        $q->execute([$key]); $v=$q->fetchColumn(); return $v===false?$default:$v;
    } catch(Throwable) { return $default; }
}

function audit(string $action, string $entityType, ?int $entityId=null, array $meta=[]): void {
    try {
        $stmt=db()->prepare('INSERT INTO audit_logs(user_id,action,entity_type,entity_id,metadata_json,ip_address,user_agent) VALUES(?,?,?,?,?,?,?)');
        $stmt->execute([current_user_id(),$action,$entityType,$entityId,$meta?json_encode($meta,JSON_UNESCAPED_SLASHES):null,$_SERVER['REMOTE_ADDR']??null,substr((string)($_SERVER['HTTP_USER_AGENT']??''),0,500)]);
    } catch(Throwable) {}
}

function create_notification(int $userId,string $type,string $title,string $message,?string $dedupe=null,?string $actionUrl=null): void {
    try {
        $q=db()->prepare('INSERT IGNORE INTO notifications(user_id,type,title,message,action_url,dedupe_key) VALUES(?,?,?,?,?,?)');
        $q->execute([$userId,$type,$title,$message,$actionUrl,$dedupe]);
    } catch(Throwable) {}
}

function task_can_transition(string $from,string $to): bool {
    $map=[
        'backlog'=>['to_do','cancelled'],'to_do'=>['in_progress','blocked','cancelled'],
        'in_progress'=>['blocked','in_review','completed','cancelled'],'blocked'=>['in_progress','cancelled'],
        'in_review'=>['in_progress','completed'],'completed'=>['in_progress'],'cancelled'=>['backlog','to_do'],
    ];
    return $from===$to || in_array($to,$map[$from]??[],true);
}

function campaign_progress(array $campaign,int $counted,int $todayCount=0,?DateTimeImmutable $now=null): array {
    $tz=new DateTimeZone((string)($campaign['timezone']??config('app.timezone','Asia/Qatar')));
    $now=$now?$now->setTimezone($tz):new DateTimeImmutable('now',$tz);
    $start=new DateTimeImmutable((string)$campaign['start_date'].' 00:00:00',$tz);
    $deadline=new DateTimeImmutable((string)$campaign['deadline'].' 23:59:59',$tz);
    $target=max(1,(int)$campaign['target_count']); $remaining=max($target-$counted,0);
    $percentage=($counted/$target)*100; $visual=min(100,max(0,$percentage));
    $totalDays=max(1,(int)$start->diff($deadline)->days);
    if($now<$start){$elapsed=0;$remainingDays=$totalDays;}
    elseif($now>$deadline){$elapsed=$totalDays;$remainingDays=0;}
    else{$elapsed=max(1,(int)$start->diff($now)->days+1);$remainingDays=max(1,(int)$now->setTime(0,0)->diff($deadline->setTime(0,0))->days+1);}
    $avg=$elapsed>0?$counted/$elapsed:0.0; $required=$remainingDays>0?$remaining/$remainingDays:0.0;
    $dailyTarget=$target/$totalDays; $planned=min($target,$dailyTarget*$elapsed); $delta=$counted-$planned;
    $projected=null; if($avg>0&&$remaining>0)$projected=$now->modify('+'.(int)ceil($remaining/$avg).' days')->format('Y-m-d'); elseif($remaining===0)$projected=$now->format('Y-m-d');
    return ['target'=>$target,'counted'=>$counted,'remaining'=>$remaining,'percentage'=>$percentage,'visual_percentage'=>$visual,'total_days'=>$totalDays,'days_elapsed'=>$elapsed,'days_remaining'=>$remainingDays,'average_daily'=>$avg,'required_daily'=>$required,'daily_target'=>$dailyTarget,'today_count'=>$todayCount,'planned_to_date'=>$planned,'pace_delta'=>$delta,'pace_status'=>$delta>=0?'on-track':'behind','projected_completion_date'=>$projected,'is_complete'=>$counted>=$target,'is_expired'=>$now>$deadline,'start_date'=>$campaign['start_date'],'deadline'=>$campaign['deadline']];
}

function pagination_meta(int $total,int $page,int $per=15): array { $pages=max(1,(int)ceil($total/$per));$page=max(1,min($page,$pages));return ['total'=>$total,'page'=>$page,'pages'=>$pages,'per'=>$per,'offset'=>($page-1)*$per]; }

function json_response(array $data,int $status=200): never { http_response_code($status); header('Content-Type: application/json; charset=utf-8'); echo json_encode($data,JSON_UNESCAPED_SLASHES); exit; }

function brand_logo_url(): ?string {
    $relative=trim((string)setting('brand_logo_path',''));
    if($relative==='')return null;
    $relative=ltrim(str_replace('\\','/',$relative),'/');
    if(str_contains($relative,'..'))return null;
    $full=PROJECT_ROOT.'/'.$relative;
    return is_file($full)?url($relative):null;
}
