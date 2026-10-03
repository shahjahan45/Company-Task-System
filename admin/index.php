<?php
require dirname(__DIR__).'/includes/bootstrap.php';
if(!installed())redirect('setup.php');
if(!current_user_id()||!current_user())redirect('login.php');
redirect('dashboard.php');
