# Security notes

The application uses password hashing, secure PHP sessions, CSRF tokens, server-side role/permission checks, PDO prepared statements, output escaping, login throttling, duplicate registration constraints and audit logs. For production, enable HTTPS, use a non-root MySQL account, keep backups outside the web root and disable detailed PHP error display.
