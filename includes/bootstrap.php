<?php
declare(strict_types=1);

define('PROJECT_ROOT', dirname(__DIR__));
$GLOBALS['IDRIVER_CONFIG'] = require PROJECT_ROOT . '/config.php';

require_once __DIR__ . '/functions.php';

$secure = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off');
session_name((string)config('app.session_name', 'idriver_command_center'));
session_set_cookie_params([
    'lifetime' => 0,
    'path' => '/',
    'secure' => $secure,
    'httponly' => true,
    'samesite' => 'Lax',
]);
if (session_status() !== PHP_SESSION_ACTIVE) session_start();

date_default_timezone_set((string)config('app.timezone', 'Asia/Qatar'));

if (!isset($_SESSION['_csrf'])) $_SESSION['_csrf'] = bin2hex(random_bytes(32));

require_once __DIR__ . '/db.php';
require_once __DIR__ . '/auth.php';

if (schema_ready()) ensure_runtime_schema();
