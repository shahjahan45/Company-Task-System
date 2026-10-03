<?php
require dirname(__DIR__).'/includes/bootstrap.php';require_auth();verify_csrf();$id=(int)($_POST['id']??0);$q=db()->prepare('UPDATE notifications SET read_at=UTC_TIMESTAMP() WHERE id=? AND user_id=?');$q->execute([$id,current_user_id()]);redirect('notifications.php');
