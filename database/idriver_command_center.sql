-- iDriver Operations & Growth Command Center
-- MySQL 8+ database schema + seed data
-- Generated for the zero-command XAMPP build
-- Database: idriver_command_center

SET NAMES utf8mb4;
SET time_zone = '+03:00';
SET FOREIGN_KEY_CHECKS = 0;

CREATE DATABASE IF NOT EXISTS `idriver_command_center`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `idriver_command_center`;


CREATE TABLE IF NOT EXISTS roles (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(80) NOT NULL,
  slug VARCHAR(80) NOT NULL UNIQUE,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS permissions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  slug VARCHAR(120) NOT NULL UNIQUE,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS role_permissions (
  role_id BIGINT UNSIGNED NOT NULL,
  permission_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY(role_id, permission_id),
  CONSTRAINT fk_rp_role FOREIGN KEY(role_id) REFERENCES roles(id) ON DELETE CASCADE,
  CONSTRAINT fk_rp_perm FOREIGN KEY(permission_id) REFERENCES permissions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS departments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  slug VARCHAR(120) NOT NULL UNIQUE,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(190) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  account_status ENUM('active','inactive','locked') NOT NULL DEFAULT 'active',
  last_login_at DATETIME NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_users_status(account_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_roles (
  user_id BIGINT UNSIGNED NOT NULL,
  role_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY(user_id, role_id),
  CONSTRAINT fk_ur_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_ur_role FOREIGN KEY(role_id) REFERENCES roles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS employees (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NULL UNIQUE,
  employee_code VARCHAR(40) NOT NULL UNIQUE,
  full_name VARCHAR(160) NOT NULL,
  work_email VARCHAR(190) NOT NULL UNIQUE,
  contact_number VARCHAR(40) NULL,
  department_id BIGINT UNSIGNED NULL,
  job_title VARCHAR(120) NULL,
  manager_id BIGINT UNSIGNED NULL,
  employment_status ENUM('active','inactive','on_leave','terminated') NOT NULL DEFAULT 'active',
  joining_date DATE NULL,
  profile_image VARCHAR(255) NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_emp_department(department_id), INDEX idx_emp_status(employment_status),
  CONSTRAINT fk_emp_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_emp_dept FOREIGN KEY(department_id) REFERENCES departments(id) ON DELETE SET NULL,
  CONSTRAINT fk_emp_manager FOREIGN KEY(manager_id) REFERENCES employees(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS campaigns (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(180) NOT NULL,
  start_date DATE NOT NULL,
  deadline DATE NOT NULL,
  target_count INT UNSIGNED NOT NULL,
  count_statuses_json JSON NULL,
  timezone VARCHAR(80) NOT NULL DEFAULT 'Asia/Qatar',
  daily_distribution ENUM('even','custom') NOT NULL DEFAULT 'even',
  manager_employee_id BIGINT UNSIGNED NULL,
  status ENUM('draft','active','completed','cancelled') NOT NULL DEFAULT 'active',
  alert_thresholds_json JSON NULL,
  notes TEXT NULL,
  created_by BIGINT UNSIGNED NULL,
  updated_by BIGINT UNSIGNED NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_campaign_dates(start_date,deadline), INDEX idx_campaign_status(status),
  CONSTRAINT fk_campaign_manager FOREIGN KEY(manager_employee_id) REFERENCES employees(id) ON DELETE SET NULL,
  CONSTRAINT fk_campaign_created_by FOREIGN KEY(created_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_campaign_updated_by FOREIGN KEY(updated_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS drivers (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  driver_code VARCHAR(40) NOT NULL UNIQUE,
  full_name VARCHAR(160) NOT NULL,
  phone VARCHAR(40) NOT NULL,
  phone_normalized VARCHAR(40) NOT NULL UNIQUE,
  registration_at DATETIME NOT NULL,
  status ENUM('lead','registered','verification_pending','verified','rejected','inactive') NOT NULL DEFAULT 'verification_pending',
  registration_source VARCHAR(100) NULL,
  assigned_employee_id BIGINT UNSIGNED NULL,
  verification_status ENUM('pending','verified','rejected') NOT NULL DEFAULT 'pending',
  verified_at DATETIME NULL,
  notes TEXT NULL,
  created_by BIGINT UNSIGNED NULL,
  updated_by BIGINT UNSIGNED NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_driver_registration(registration_at), INDEX idx_driver_status(status), INDEX idx_driver_employee(assigned_employee_id),
  CONSTRAINT fk_driver_employee FOREIGN KEY(assigned_employee_id) REFERENCES employees(id) ON DELETE SET NULL,
  CONSTRAINT fk_driver_created FOREIGN KEY(created_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_driver_updated FOREIGN KEY(updated_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS driver_status_history (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  driver_id BIGINT UNSIGNED NOT NULL,
  from_status VARCHAR(40) NULL,
  to_status VARCHAR(40) NOT NULL,
  reason VARCHAR(500) NULL,
  changed_by BIGINT UNSIGNED NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_dsh_driver(driver_id,created_at),
  CONSTRAINT fk_dsh_driver FOREIGN KEY(driver_id) REFERENCES drivers(id) ON DELETE CASCADE,
  CONSTRAINT fk_dsh_user FOREIGN KEY(changed_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS campaign_registrations (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  campaign_id BIGINT UNSIGNED NOT NULL,
  driver_id BIGINT UNSIGNED NOT NULL,
  counted TINYINT(1) NOT NULL DEFAULT 0,
  counted_at DATETIME NULL,
  attribution_employee_id BIGINT UNSIGNED NULL,
  registration_source VARCHAR(100) NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_campaign_driver(campaign_id,driver_id),
  INDEX idx_cr_counted(campaign_id,counted,counted_at),
  CONSTRAINT fk_cr_campaign FOREIGN KEY(campaign_id) REFERENCES campaigns(id) ON DELETE CASCADE,
  CONSTRAINT fk_cr_driver FOREIGN KEY(driver_id) REFERENCES drivers(id) ON DELETE CASCADE,
  CONSTRAINT fk_cr_employee FOREIGN KEY(attribution_employee_id) REFERENCES employees(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS task_categories (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tasks (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  task_code VARCHAR(40) NOT NULL UNIQUE,
  title VARCHAR(220) NOT NULL,
  description TEXT NULL,
  category_id BIGINT UNSIGNED NULL,
  priority ENUM('low','medium','high','urgent') NOT NULL DEFAULT 'medium',
  created_by BIGINT UNSIGNED NULL,
  primary_assignee_id BIGINT UNSIGNED NULL,
  start_date DATE NULL,
  due_at DATETIME NULL,
  status ENUM('backlog','to_do','in_progress','blocked','in_review','completed','cancelled') NOT NULL DEFAULT 'to_do',
  progress TINYINT UNSIGNED NOT NULL DEFAULT 0,
  completed_at DATETIME NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_task_status(status), INDEX idx_task_due(due_at), INDEX idx_task_assignee(primary_assignee_id), INDEX idx_task_created(created_at),
  CONSTRAINT fk_task_category FOREIGN KEY(category_id) REFERENCES task_categories(id) ON DELETE SET NULL,
  CONSTRAINT fk_task_creator FOREIGN KEY(created_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_task_assignee FOREIGN KEY(primary_assignee_id) REFERENCES employees(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS task_assignees (
  task_id BIGINT UNSIGNED NOT NULL,
  employee_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY(task_id,employee_id),
  CONSTRAINT fk_ta_task FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE CASCADE,
  CONSTRAINT fk_ta_emp FOREIGN KEY(employee_id) REFERENCES employees(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS task_checklists (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  task_id BIGINT UNSIGNED NOT NULL,
  item_text VARCHAR(500) NOT NULL,
  is_completed TINYINT(1) NOT NULL DEFAULT 0,
  sort_order INT NOT NULL DEFAULT 0,
  completed_at DATETIME NULL,
  INDEX idx_check_task(task_id),
  CONSTRAINT fk_check_task FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS task_comments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  task_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NULL,
  body TEXT NOT NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_comment_task(task_id,created_at),
  CONSTRAINT fk_comment_task FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE CASCADE,
  CONSTRAINT fk_comment_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS task_attachments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  task_id BIGINT UNSIGNED NOT NULL,
  uploaded_by BIGINT UNSIGNED NULL,
  original_name VARCHAR(255) NOT NULL,
  storage_path VARCHAR(255) NOT NULL,
  mime_type VARCHAR(120) NOT NULL,
  file_size BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_attachment_task(task_id),
  CONSTRAINT fk_attachment_task FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE CASCADE,
  CONSTRAINT fk_attachment_user FOREIGN KEY(uploaded_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS task_activity_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  task_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NULL,
  action VARCHAR(100) NOT NULL,
  from_value VARCHAR(255) NULL,
  to_value VARCHAR(255) NULL,
  metadata_json JSON NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tal_task(task_id,created_at),
  CONSTRAINT fk_tal_task FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE CASCADE,
  CONSTRAINT fk_tal_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS notifications (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  type VARCHAR(80) NOT NULL,
  title VARCHAR(180) NOT NULL,
  message VARCHAR(800) NOT NULL,
  action_url VARCHAR(255) NULL,
  dedupe_key VARCHAR(190) NULL,
  read_at DATETIME NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_notification_dedupe(user_id,dedupe_key),
  INDEX idx_notification_user(user_id,read_at,created_at),
  CONSTRAINT fk_notification_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS notification_preferences (
  user_id BIGINT UNSIGNED PRIMARY KEY,
  assignment TINYINT(1) NOT NULL DEFAULT 1,
  deadlines TINYINT(1) NOT NULL DEFAULT 1,
  overdue TINYINT(1) NOT NULL DEFAULT 1,
  campaign_milestones TINYINT(1) NOT NULL DEFAULT 1,
  email_enabled TINYINT(1) NOT NULL DEFAULT 0,
  CONSTRAINT fk_np_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS daily_activity (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  activity_date DATE NOT NULL,
  department_id BIGINT UNSIGNED NULL,
  employee_id BIGINT UNSIGNED NULL,
  metric_key VARCHAR(100) NOT NULL,
  metric_value DECIMAL(14,2) NOT NULL DEFAULT 0,
  metadata_json JSON NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_daily_metric(activity_date,employee_id,metric_key),
  CONSTRAINT fk_da_dept FOREIGN KEY(department_id) REFERENCES departments(id) ON DELETE SET NULL,
  CONSTRAINT fk_da_emp FOREIGN KEY(employee_id) REFERENCES employees(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS audit_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NULL,
  action VARCHAR(120) NOT NULL,
  entity_type VARCHAR(100) NOT NULL,
  entity_id BIGINT UNSIGNED NULL,
  metadata_json JSON NULL,
  ip_address VARCHAR(64) NULL,
  user_agent VARCHAR(500) NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_audit_entity(entity_type,entity_id), INDEX idx_audit_user(user_id,created_at),
  CONSTRAINT fk_audit_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS system_settings (
  setting_key VARCHAR(120) PRIMARY KEY,
  setting_value TEXT NULL,
  setting_type VARCHAR(30) NOT NULL DEFAULT 'string',
  is_public TINYINT(1) NOT NULL DEFAULT 0,
  updated_by BIGINT UNSIGNED NULL,
  updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_setting_user FOREIGN KEY(updated_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS login_attempts (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(190) NOT NULL,
  ip_address VARCHAR(64) NOT NULL,
  successful TINYINT(1) NOT NULL DEFAULT 0,
  attempted_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_login_attempt(email,ip_address,attempted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS password_reset_tokens (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  token_hash VARCHAR(255) NOT NULL UNIQUE,
  expires_at DATETIME NOT NULL,
  used_at DATETIME NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_reset_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Default roles, permissions, departments, categories, campaign and settings

INSERT IGNORE INTO roles (name,slug) VALUES
('Super Administrator','super_admin'),('Administrator','admin'),('Manager','manager'),('Employee','employee'),('Read-Only Management','read_only');

INSERT IGNORE INTO permissions (name,slug) VALUES
('View dashboard','dashboard.view'),('View drivers','drivers.view'),('Create drivers','drivers.create'),('Edit drivers','drivers.edit'),('Verify drivers','drivers.verify'),('Export drivers','drivers.export'),
('View employees','employees.view'),('Manage employees','employees.manage'),('View tasks','tasks.view'),('Create tasks','tasks.create'),('Edit tasks','tasks.edit'),('Review tasks','tasks.review'),
('View campaigns','campaigns.view'),('Manage campaigns','campaigns.manage'),('View reports','reports.view'),('Export reports','reports.export'),('View audit logs','audit.view'),
('View notifications','notifications.view'),('Manage settings','settings.manage'),('Manage roles','roles.manage');

INSERT IGNORE INTO role_permissions (role_id,permission_id)
SELECT r.id,p.id FROM roles r CROSS JOIN permissions p WHERE r.slug='super_admin';

INSERT IGNORE INTO role_permissions (role_id,permission_id)
SELECT r.id,p.id FROM roles r JOIN permissions p ON p.slug IN ('dashboard.view','drivers.view','drivers.create','drivers.edit','drivers.verify','drivers.export','employees.view','employees.manage','tasks.view','tasks.create','tasks.edit','tasks.review','campaigns.view','campaigns.manage','reports.view','reports.export','audit.view','notifications.view','settings.manage') WHERE r.slug='admin';

INSERT IGNORE INTO role_permissions (role_id,permission_id)
SELECT r.id,p.id FROM roles r JOIN permissions p ON p.slug IN ('dashboard.view','drivers.view','drivers.create','drivers.edit','drivers.verify','employees.view','tasks.view','tasks.create','tasks.edit','tasks.review','campaigns.view','reports.view','notifications.view') WHERE r.slug='manager';

INSERT IGNORE INTO role_permissions (role_id,permission_id)
SELECT r.id,p.id FROM roles r JOIN permissions p ON p.slug IN ('dashboard.view','drivers.view','drivers.create','tasks.view','tasks.edit','notifications.view') WHERE r.slug='employee';

INSERT IGNORE INTO role_permissions (role_id,permission_id)
SELECT r.id,p.id FROM roles r JOIN permissions p ON p.slug IN ('dashboard.view','drivers.view','employees.view','tasks.view','campaigns.view','reports.view','notifications.view') WHERE r.slug='read_only';

INSERT IGNORE INTO departments (name,slug) VALUES ('Operations','operations'),('Driver Growth','driver-growth'),('Customer Support','customer-support'),('Management','management');
INSERT IGNORE INTO task_categories (name) VALUES ('Operations'),('Driver Growth'),('Administration'),('Customer Support'),('Marketing');

INSERT INTO campaigns (name,start_date,deadline,target_count,count_statuses_json,timezone,status,notes)
SELECT 'iDriver 2,000 Drivers Campaign','2026-09-28','2026-10-28',2000,JSON_ARRAY('verified'),'Asia/Qatar','active','Default growth campaign from the project brief.'
WHERE NOT EXISTS (SELECT 1 FROM campaigns WHERE name='iDriver 2,000 Drivers Campaign');

INSERT INTO system_settings (setting_key,setting_value,setting_type,is_public) VALUES
('company_name','iDriver Technology','string',1),('business_timezone','Asia/Qatar','string',1),('dashboard_refresh_seconds','20','integer',1),('date_format','d M Y','string',1)
ON DUPLICATE KEY UPDATE setting_key=VALUES(setting_key);

SET FOREIGN_KEY_CHECKS = 1;

-- Administrator account is intentionally not hardcoded here.
-- On first visit to http://localhost/idriver-command-center the browser installer
-- creates the first Super Administrator securely.

-- Public dashboard defaults. These values are safe to expose and are editable in Admin > Settings.
INSERT INTO system_settings (setting_key,setting_value,setting_type,is_public) VALUES
('public_dashboard_enabled','1','boolean',1),
('public_hero_badge','Live operations intelligence','string',1),
('public_hero_title','Growth in motion. Progress you can see.','string',1),
('public_hero_subtitle','A live, read-only view of iDriver growth, campaign momentum, and operational execution.','string',1),
('public_notice','','string',1),
('public_refresh_seconds','20','integer',1),
('public_footer_text','Live operations visibility powered by the iDriver Command Center.','string',1),
('public_nav_subtitle','Operations & Growth Command Center','string',1),
('brand_logo_path','','string',1),
('public_show_driver_growth','1','boolean',1),
('public_show_employee_performance','1','boolean',1),
('public_show_employee_tasks','1','boolean',1),
('public_show_operations','1','boolean',1),
('public_show_task_feed','1','boolean',1),
('public_show_team','1','boolean',1),
('public_show_campaigns','1','boolean',1),
('public_show_activity','1','boolean',1)
ON DUPLICATE KEY UPDATE setting_key=VALUES(setting_key);


-- DEMO DATA: 6 sample employee users, 45 verified drivers, 30 tasks
-- Demo account password for all sample users: Demo@12345
INSERT IGNORE INTO users(id,email,password_hash,account_status) VALUES(1001,'layla.demo@idriver.local','$2y$12$FKdD.hzQEW0DzHDCgT0T.uNWIIV4.gubxcMKlz3ckdjb.8kCL7VXq','active');
INSERT IGNORE INTO user_roles(user_id,role_id) SELECT 1001,id FROM roles WHERE slug='manager';
INSERT IGNORE INTO employees(id,user_id,employee_code,full_name,work_email,contact_number,department_id,job_title,employment_status,joining_date) SELECT 1001,1001,'EMP-1001','Layla Hassan','layla.demo@idriver.local','+974 4400 1001',d.id,'Growth Manager','active','2026-09-01' FROM departments d WHERE d.slug='driver-growth';
INSERT IGNORE INTO users(id,email,password_hash,account_status) VALUES(1002,'omar.demo@idriver.local','$2y$12$FKdD.hzQEW0DzHDCgT0T.uNWIIV4.gubxcMKlz3ckdjb.8kCL7VXq','active');
INSERT IGNORE INTO user_roles(user_id,role_id) SELECT 1002,id FROM roles WHERE slug='employee';
INSERT IGNORE INTO employees(id,user_id,employee_code,full_name,work_email,contact_number,department_id,job_title,employment_status,joining_date) SELECT 1002,1002,'EMP-1002','Omar Farooq','omar.demo@idriver.local','+974 4400 1002',d.id,'Driver Acquisition Executive','active','2026-09-01' FROM departments d WHERE d.slug='driver-growth';
INSERT IGNORE INTO users(id,email,password_hash,account_status) VALUES(1003,'noor.demo@idriver.local','$2y$12$FKdD.hzQEW0DzHDCgT0T.uNWIIV4.gubxcMKlz3ckdjb.8kCL7VXq','active');
INSERT IGNORE INTO user_roles(user_id,role_id) SELECT 1003,id FROM roles WHERE slug='employee';
INSERT IGNORE INTO employees(id,user_id,employee_code,full_name,work_email,contact_number,department_id,job_title,employment_status,joining_date) SELECT 1003,1003,'EMP-1003','Noor Ali','noor.demo@idriver.local','+974 4400 1003',d.id,'Operations Coordinator','active','2026-09-01' FROM departments d WHERE d.slug='operations';
INSERT IGNORE INTO users(id,email,password_hash,account_status) VALUES(1004,'rafiq.demo@idriver.local','$2y$12$FKdD.hzQEW0DzHDCgT0T.uNWIIV4.gubxcMKlz3ckdjb.8kCL7VXq','active');
INSERT IGNORE INTO user_roles(user_id,role_id) SELECT 1004,id FROM roles WHERE slug='employee';
INSERT IGNORE INTO employees(id,user_id,employee_code,full_name,work_email,contact_number,department_id,job_title,employment_status,joining_date) SELECT 1004,1004,'EMP-1004','Rafiq Rahman','rafiq.demo@idriver.local','+974 4400 1004',d.id,'Verification Specialist','active','2026-09-01' FROM departments d WHERE d.slug='operations';
INSERT IGNORE INTO users(id,email,password_hash,account_status) VALUES(1005,'maya.demo@idriver.local','$2y$12$FKdD.hzQEW0DzHDCgT0T.uNWIIV4.gubxcMKlz3ckdjb.8kCL7VXq','active');
INSERT IGNORE INTO user_roles(user_id,role_id) SELECT 1005,id FROM roles WHERE slug='employee';
INSERT IGNORE INTO employees(id,user_id,employee_code,full_name,work_email,contact_number,department_id,job_title,employment_status,joining_date) SELECT 1005,1005,'EMP-1005','Maya Joseph','maya.demo@idriver.local','+974 4400 1005',d.id,'Customer Support Executive','active','2026-09-01' FROM departments d WHERE d.slug='customer-support';
INSERT IGNORE INTO users(id,email,password_hash,account_status) VALUES(1006,'samir.demo@idriver.local','$2y$12$FKdD.hzQEW0DzHDCgT0T.uNWIIV4.gubxcMKlz3ckdjb.8kCL7VXq','active');
INSERT IGNORE INTO user_roles(user_id,role_id) SELECT 1006,id FROM roles WHERE slug='employee';
INSERT IGNORE INTO employees(id,user_id,employee_code,full_name,work_email,contact_number,department_id,job_title,employment_status,joining_date) SELECT 1006,1006,'EMP-1006','Samir Khan','samir.demo@idriver.local','+974 4400 1006',d.id,'Operations Executive','active','2026-09-01' FROM departments d WHERE d.slug='operations';
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2001,'DRV-DEMO-001','Aamir Ahmed','+974 55000001','97455000001','2026-09-28 08:00:00','verified','Office Campaign',1001,'verified','2026-09-28 08:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2001,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2002,'DRV-DEMO-002','Bilal Khan','+974 55000002','97455000002','2026-09-28 11:00:00','verified','Referral',1002,'verified','2026-09-28 11:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2002,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2003,'DRV-DEMO-003','Danish Rahman','+974 55000003','97455000003','2026-09-28 14:00:00','verified','Field Activation',1003,'verified','2026-09-28 14:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2003,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2004,'DRV-DEMO-004','Fahad Ali','+974 55000004','97455000004','2026-09-28 17:00:00','verified','WhatsApp Lead',1004,'verified','2026-09-28 17:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2004,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2005,'DRV-DEMO-005','Hamza Hussain','+974 55000005','97455000005','2026-09-28 20:00:00','verified','Community Outreach',1005,'verified','2026-09-28 20:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2005,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2006,'DRV-DEMO-006','Imran Farooq','+974 55000006','97455000006','2026-09-28 23:00:00','verified','Office Campaign',1006,'verified','2026-09-28 23:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2006,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2007,'DRV-DEMO-007','Junaid Malik','+974 55000007','97455000007','2026-09-29 02:00:00','verified','Referral',1001,'verified','2026-09-29 02:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2007,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2008,'DRV-DEMO-008','Kareem Sheikh','+974 55000008','97455000008','2026-09-29 05:00:00','verified','Field Activation',1002,'verified','2026-09-29 05:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2008,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2009,'DRV-DEMO-009','Nabeel Qureshi','+974 55000009','97455000009','2026-09-29 08:00:00','verified','WhatsApp Lead',1003,'verified','2026-09-29 08:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2009,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2010,'DRV-DEMO-010','Qasim Ansari','+974 55000010','97455000010','2026-09-29 11:00:00','verified','Community Outreach',1004,'verified','2026-09-29 11:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2010,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2011,'DRV-DEMO-011','Rayan Ahmed','+974 55000011','97455000011','2026-09-29 14:00:00','verified','Office Campaign',1005,'verified','2026-09-29 14:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2011,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2012,'DRV-DEMO-012','Tariq Khan','+974 55000012','97455000012','2026-09-29 17:00:00','verified','Referral',1006,'verified','2026-09-29 17:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2012,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2013,'DRV-DEMO-013','Yasir Rahman','+974 55000013','97455000013','2026-09-29 20:00:00','verified','Field Activation',1001,'verified','2026-09-29 20:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2013,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2014,'DRV-DEMO-014','Zaid Ali','+974 55000014','97455000014','2026-09-29 23:00:00','verified','WhatsApp Lead',1002,'verified','2026-09-29 23:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2014,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2015,'DRV-DEMO-015','Arman Hussain','+974 55000015','97455000015','2026-09-30 02:00:00','verified','Community Outreach',1003,'verified','2026-09-30 02:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2015,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2016,'DRV-DEMO-016','Farhan Farooq','+974 55000016','97455000016','2026-09-30 05:00:00','verified','Office Campaign',1004,'verified','2026-09-30 05:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2016,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2017,'DRV-DEMO-017','Irfan Malik','+974 55000017','97455000017','2026-09-30 08:00:00','verified','Referral',1005,'verified','2026-09-30 08:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2017,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2018,'DRV-DEMO-018','Khalid Sheikh','+974 55000018','97455000018','2026-09-30 11:00:00','verified','Field Activation',1006,'verified','2026-09-30 11:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2018,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2019,'DRV-DEMO-019','Mahmoud Qureshi','+974 55000019','97455000019','2026-09-30 14:00:00','verified','WhatsApp Lead',1001,'verified','2026-09-30 14:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2019,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2020,'DRV-DEMO-020','Nasser Ansari','+974 55000020','97455000020','2026-09-30 17:00:00','verified','Community Outreach',1002,'verified','2026-09-30 17:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2020,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2021,'DRV-DEMO-021','Sameer Ahmed','+974 55000021','97455000021','2026-09-30 20:00:00','verified','Office Campaign',1003,'verified','2026-09-30 20:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2021,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2022,'DRV-DEMO-022','Waleed Khan','+974 55000022','97455000022','2026-09-30 23:00:00','verified','Referral',1004,'verified','2026-09-30 23:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2022,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2023,'DRV-DEMO-023','Adil Rahman','+974 55000023','97455000023','2026-10-01 02:00:00','verified','Field Activation',1005,'verified','2026-10-01 02:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2023,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2024,'DRV-DEMO-024','Bashir Ali','+974 55000024','97455000024','2026-10-01 05:00:00','verified','WhatsApp Lead',1006,'verified','2026-10-01 05:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2024,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2025,'DRV-DEMO-025','Hassan Hussain','+974 55000025','97455000025','2026-10-01 08:00:00','verified','Community Outreach',1001,'verified','2026-10-01 08:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2025,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2026,'DRV-DEMO-026','Jamal Farooq','+974 55000026','97455000026','2026-10-01 11:00:00','verified','Office Campaign',1002,'verified','2026-10-01 11:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2026,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2027,'DRV-DEMO-027','Mazin Malik','+974 55000027','97455000027','2026-10-01 14:00:00','verified','Referral',1003,'verified','2026-10-01 14:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2027,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2028,'DRV-DEMO-028','Nadeem Sheikh','+974 55000028','97455000028','2026-10-01 17:00:00','verified','Field Activation',1004,'verified','2026-10-01 17:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2028,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2029,'DRV-DEMO-029','Rashid Qureshi','+974 55000029','97455000029','2026-10-01 20:00:00','verified','WhatsApp Lead',1005,'verified','2026-10-01 20:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2029,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2030,'DRV-DEMO-030','Salman Ansari','+974 55000030','97455000030','2026-10-01 23:00:00','verified','Community Outreach',1006,'verified','2026-10-01 23:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2030,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2031,'DRV-DEMO-031','Talal Ahmed','+974 55000031','97455000031','2026-10-02 02:00:00','verified','Office Campaign',1001,'verified','2026-10-02 02:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2031,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2032,'DRV-DEMO-032','Usman Khan','+974 55000032','97455000032','2026-10-02 05:00:00','verified','Referral',1002,'verified','2026-10-02 05:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2032,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2033,'DRV-DEMO-033','Waqar Rahman','+974 55000033','97455000033','2026-10-02 08:00:00','verified','Field Activation',1003,'verified','2026-10-02 08:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2033,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2034,'DRV-DEMO-034','Zubair Ali','+974 55000034','97455000034','2026-10-02 11:00:00','verified','WhatsApp Lead',1004,'verified','2026-10-02 11:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2034,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2035,'DRV-DEMO-035','Adeel Hussain','+974 55000035','97455000035','2026-10-02 14:00:00','verified','Community Outreach',1005,'verified','2026-10-02 14:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2035,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2036,'DRV-DEMO-036','Faizan Farooq','+974 55000036','97455000036','2026-10-02 17:00:00','verified','Office Campaign',1006,'verified','2026-10-02 17:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2036,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2037,'DRV-DEMO-037','Haroon Malik','+974 55000037','97455000037','2026-10-02 20:00:00','verified','Referral',1001,'verified','2026-10-02 20:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2037,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2038,'DRV-DEMO-038','Ilyas Sheikh','+974 55000038','97455000038','2026-10-02 23:00:00','verified','Field Activation',1002,'verified','2026-10-02 23:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2038,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2039,'DRV-DEMO-039','Kamran Qureshi','+974 55000039','97455000039','2026-10-03 02:00:00','verified','WhatsApp Lead',1003,'verified','2026-10-03 02:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2039,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2040,'DRV-DEMO-040','Luqman Ansari','+974 55000040','97455000040','2026-10-03 05:00:00','verified','Community Outreach',1004,'verified','2026-10-03 05:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2040,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2041,'DRV-DEMO-041','Mustafa Ahmed','+974 55000041','97455000041','2026-10-03 08:00:00','verified','Office Campaign',1005,'verified','2026-10-03 08:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2041,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2042,'DRV-DEMO-042','Rizwan Khan','+974 55000042','97455000042','2026-10-03 11:00:00','verified','Referral',1006,'verified','2026-10-03 11:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2042,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2043,'DRV-DEMO-043','Shahid Rahman','+974 55000043','97455000043','2026-10-03 14:00:00','verified','Field Activation',1001,'verified','2026-10-03 14:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2043,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2044,'DRV-DEMO-044','Sohail Ali','+974 55000044','97455000044','2026-10-03 17:00:00','verified','WhatsApp Lead',1002,'verified','2026-10-03 17:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2044,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO drivers(id,driver_code,full_name,phone,phone_normalized,registration_at,status,registration_source,assigned_employee_id,verification_status,verified_at,notes) VALUES(2045,'DRV-DEMO-045','Zayan Hussain','+974 55000045','97455000045','2026-10-03 20:00:00','verified','Community Outreach',1003,'verified','2026-10-03 20:00:00','Demo driver record for dashboard testing.');
INSERT IGNORE INTO driver_status_history(driver_id,from_status,to_status,reason,changed_by) VALUES(2045,NULL,'verified','Demo seed verified driver',NULL);
INSERT IGNORE INTO campaign_registrations(campaign_id,driver_id,counted,counted_at,attribution_employee_id,registration_source) SELECT c.id,d.id,1,d.verified_at,d.assigned_employee_id,d.registration_source FROM campaigns c JOIN drivers d ON d.id BETWEEN 2001 AND 2045 WHERE c.name='iDriver 2,000 Drivers Campaign';
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3001,'TSK-DEMO-001','Confirm morning driver follow-up list — Layla','Demo task for Layla Hassan. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'high',NULL,1001,'2026-09-30','2026-10-03 17:00:00','completed',100,'2026-10-01 10:00:00' FROM task_categories tc WHERE tc.name='Driver Growth';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3001,1001);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3001,NULL,'demo_seed',NULL,'completed');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3002,'TSK-DEMO-002','Validate new driver documents — Layla','Demo task for Layla Hassan. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'medium',NULL,1001,'2026-09-30','2026-10-04 17:00:00','completed',100,'2026-10-02 11:00:00' FROM task_categories tc WHERE tc.name='Operations';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3002,1001);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3002,NULL,'demo_seed',NULL,'completed');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3003,'TSK-DEMO-003','Call pending registration leads — Layla','Demo task for Layla Hassan. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'urgent',NULL,1001,'2026-09-30','2026-10-05 17:00:00','completed',100,'2026-10-01 12:00:00' FROM task_categories tc WHERE tc.name='Driver Growth';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3003,1001);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3003,NULL,'demo_seed',NULL,'completed');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3004,'TSK-DEMO-004','Update daily acquisition tracker — Layla','Demo task for Layla Hassan. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'medium',NULL,1001,'2026-09-30','2026-10-06 17:00:00','completed',100,'2026-10-02 13:00:00' FROM task_categories tc WHERE tc.name='Administration';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3004,1001);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3004,NULL,'demo_seed',NULL,'completed');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3005,'TSK-DEMO-005','Prepare end-of-day operations summary — Layla','Demo task for Layla Hassan. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'low',NULL,1001,'2026-09-30','2026-10-07 17:00:00','completed',100,'2026-10-01 14:00:00' FROM task_categories tc WHERE tc.name='Operations';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3005,1001);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3005,NULL,'demo_seed',NULL,'completed');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3006,'TSK-DEMO-006','Confirm morning driver follow-up list — Omar','Demo task for Omar Farooq. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'high',NULL,1002,'2026-09-30','2026-10-04 17:00:00','completed',100,'2026-10-01 10:00:00' FROM task_categories tc WHERE tc.name='Driver Growth';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3006,1002);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3006,NULL,'demo_seed',NULL,'completed');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3007,'TSK-DEMO-007','Validate new driver documents — Omar','Demo task for Omar Farooq. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'medium',NULL,1002,'2026-09-30','2026-10-05 17:00:00','completed',100,'2026-10-02 11:00:00' FROM task_categories tc WHERE tc.name='Operations';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3007,1002);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3007,NULL,'demo_seed',NULL,'completed');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3008,'TSK-DEMO-008','Call pending registration leads — Omar','Demo task for Omar Farooq. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'urgent',NULL,1002,'2026-09-30','2026-10-06 17:00:00','completed',100,'2026-10-01 12:00:00' FROM task_categories tc WHERE tc.name='Driver Growth';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3008,1002);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3008,NULL,'demo_seed',NULL,'completed');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3009,'TSK-DEMO-009','Update daily acquisition tracker — Omar','Demo task for Omar Farooq. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'medium',NULL,1002,'2026-09-30','2026-10-07 17:00:00','completed',100,'2026-10-02 13:00:00' FROM task_categories tc WHERE tc.name='Administration';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3009,1002);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3009,NULL,'demo_seed',NULL,'completed');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3010,'TSK-DEMO-010','Prepare end-of-day operations summary — Omar','Demo task for Omar Farooq. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'low',NULL,1002,'2026-09-30','2026-10-08 17:00:00','in_progress',65,NULL FROM task_categories tc WHERE tc.name='Operations';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3010,1002);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3010,NULL,'demo_seed',NULL,'in_progress');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3011,'TSK-DEMO-011','Confirm morning driver follow-up list — Noor','Demo task for Noor Ali. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'high',NULL,1003,'2026-09-30','2026-10-05 17:00:00','completed',100,'2026-10-01 10:00:00' FROM task_categories tc WHERE tc.name='Driver Growth';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3011,1003);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3011,NULL,'demo_seed',NULL,'completed');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3012,'TSK-DEMO-012','Validate new driver documents — Noor','Demo task for Noor Ali. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'medium',NULL,1003,'2026-09-30','2026-10-06 17:00:00','completed',100,'2026-10-02 11:00:00' FROM task_categories tc WHERE tc.name='Operations';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3012,1003);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3012,NULL,'demo_seed',NULL,'completed');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3013,'TSK-DEMO-013','Call pending registration leads — Noor','Demo task for Noor Ali. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'urgent',NULL,1003,'2026-09-30','2026-10-07 17:00:00','completed',100,'2026-10-01 12:00:00' FROM task_categories tc WHERE tc.name='Driver Growth';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3013,1003);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3013,NULL,'demo_seed',NULL,'completed');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3014,'TSK-DEMO-014','Update daily acquisition tracker — Noor','Demo task for Noor Ali. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'medium',NULL,1003,'2026-09-30','2026-10-08 17:00:00','blocked',35,NULL FROM task_categories tc WHERE tc.name='Administration';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3014,1003);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3014,NULL,'demo_seed',NULL,'blocked');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3015,'TSK-DEMO-015','Prepare end-of-day operations summary — Noor','Demo task for Noor Ali. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'low',NULL,1003,'2026-09-30','2026-10-09 17:00:00','to_do',0,NULL FROM task_categories tc WHERE tc.name='Operations';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3015,1003);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3015,NULL,'demo_seed',NULL,'to_do');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3016,'TSK-DEMO-016','Confirm morning driver follow-up list — Rafiq','Demo task for Rafiq Rahman. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'high',NULL,1004,'2026-09-30','2026-10-03 17:00:00','completed',100,'2026-10-01 10:00:00' FROM task_categories tc WHERE tc.name='Driver Growth';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3016,1004);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3016,NULL,'demo_seed',NULL,'completed');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3017,'TSK-DEMO-017','Validate new driver documents — Rafiq','Demo task for Rafiq Rahman. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'medium',NULL,1004,'2026-09-30','2026-10-04 17:00:00','completed',100,'2026-10-02 11:00:00' FROM task_categories tc WHERE tc.name='Operations';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3017,1004);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3017,NULL,'demo_seed',NULL,'completed');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3018,'TSK-DEMO-018','Call pending registration leads — Rafiq','Demo task for Rafiq Rahman. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'urgent',NULL,1004,'2026-09-30','2026-10-05 17:00:00','to_do',0,NULL FROM task_categories tc WHERE tc.name='Driver Growth';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3018,1004);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3018,NULL,'demo_seed',NULL,'to_do');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3019,'TSK-DEMO-019','Update daily acquisition tracker — Rafiq','Demo task for Rafiq Rahman. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'medium',NULL,1004,'2026-09-30','2026-10-06 17:00:00','backlog',0,NULL FROM task_categories tc WHERE tc.name='Administration';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3019,1004);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3019,NULL,'demo_seed',NULL,'backlog');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3020,'TSK-DEMO-020','Prepare end-of-day operations summary — Rafiq','Demo task for Rafiq Rahman. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'low',NULL,1004,'2026-09-30','2026-10-07 17:00:00','in_review',90,NULL FROM task_categories tc WHERE tc.name='Operations';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3020,1004);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3020,NULL,'demo_seed',NULL,'in_review');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3021,'TSK-DEMO-021','Confirm morning driver follow-up list — Maya','Demo task for Maya Joseph. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'high',NULL,1005,'2026-09-30','2026-10-04 17:00:00','completed',100,'2026-10-01 10:00:00' FROM task_categories tc WHERE tc.name='Driver Growth';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3021,1005);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3021,NULL,'demo_seed',NULL,'completed');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3022,'TSK-DEMO-022','Validate new driver documents — Maya','Demo task for Maya Joseph. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'medium',NULL,1005,'2026-09-30','2026-10-05 17:00:00','backlog',0,NULL FROM task_categories tc WHERE tc.name='Operations';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3022,1005);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3022,NULL,'demo_seed',NULL,'backlog');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3023,'TSK-DEMO-023','Call pending registration leads — Maya','Demo task for Maya Joseph. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'urgent',NULL,1005,'2026-09-30','2026-10-06 17:00:00','in_review',90,NULL FROM task_categories tc WHERE tc.name='Driver Growth';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3023,1005);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3023,NULL,'demo_seed',NULL,'in_review');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3024,'TSK-DEMO-024','Update daily acquisition tracker — Maya','Demo task for Maya Joseph. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'medium',NULL,1005,'2026-09-30','2026-10-07 17:00:00','in_progress',65,NULL FROM task_categories tc WHERE tc.name='Administration';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3024,1005);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3024,NULL,'demo_seed',NULL,'in_progress');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3025,'TSK-DEMO-025','Prepare end-of-day operations summary — Maya','Demo task for Maya Joseph. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'low',NULL,1005,'2026-09-30','2026-10-08 17:00:00','blocked',35,NULL FROM task_categories tc WHERE tc.name='Operations';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3025,1005);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3025,NULL,'demo_seed',NULL,'blocked');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3026,'TSK-DEMO-026','Confirm morning driver follow-up list — Samir','Demo task for Samir Khan. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'high',NULL,1006,'2026-09-30','2026-10-05 17:00:00','in_review',90,NULL FROM task_categories tc WHERE tc.name='Driver Growth';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3026,1006);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3026,NULL,'demo_seed',NULL,'in_review');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3027,'TSK-DEMO-027','Validate new driver documents — Samir','Demo task for Samir Khan. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'medium',NULL,1006,'2026-09-30','2026-10-06 17:00:00','in_progress',65,NULL FROM task_categories tc WHERE tc.name='Operations';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3027,1006);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3027,NULL,'demo_seed',NULL,'in_progress');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3028,'TSK-DEMO-028','Call pending registration leads — Samir','Demo task for Samir Khan. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'urgent',NULL,1006,'2026-09-30','2026-10-07 17:00:00','blocked',35,NULL FROM task_categories tc WHERE tc.name='Driver Growth';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3028,1006);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3028,NULL,'demo_seed',NULL,'blocked');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3029,'TSK-DEMO-029','Update daily acquisition tracker — Samir','Demo task for Samir Khan. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'medium',NULL,1006,'2026-09-30','2026-10-08 17:00:00','to_do',0,NULL FROM task_categories tc WHERE tc.name='Administration';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3029,1006);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3029,NULL,'demo_seed',NULL,'to_do');
INSERT IGNORE INTO tasks(id,task_code,title,description,category_id,priority,created_by,primary_assignee_id,start_date,due_at,status,progress,completed_at) SELECT 3030,'TSK-DEMO-030','Prepare end-of-day operations summary — Samir','Demo task for Samir Khan. Used to test employee-wise task completion, progress and public dashboard visuals.',tc.id,'low',NULL,1006,'2026-09-30','2026-10-09 17:00:00','backlog',0,NULL FROM task_categories tc WHERE tc.name='Operations';
INSERT IGNORE INTO task_assignees(task_id,employee_id) VALUES(3030,1006);
INSERT IGNORE INTO task_activity_logs(task_id,user_id,action,from_value,to_value) VALUES(3030,NULL,'demo_seed',NULL,'backlog');
INSERT INTO system_settings(setting_key,setting_value,setting_type,is_public) VALUES('demo_data_loaded','1','boolean',0) ON DUPLICATE KEY UPDATE setting_value='1';
