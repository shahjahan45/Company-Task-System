<?php
return array_replace_recursive([
    'app' => [
        'name' => 'iDriver Operations & Growth Command Center',
        'timezone' => 'Asia/Qatar',
        'session_name' => 'idriver_command_center',
        'dashboard_refresh_seconds' => 20,
    ],
    'db' => [
        'host' => '127.0.0.1',
        'port' => '3306',
        'database' => 'idriver_command_center',
        'username' => 'root',
        'password' => '',
        'charset' => 'utf8mb4',
    ],
], is_file(__DIR__ . '/config.local.php') ? (require __DIR__ . '/config.local.php') : []);
