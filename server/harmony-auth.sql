-- 鸿蒙端账号密码登录所需的库结构变更
-- 在阿里云 MySQL 库 pet_reptile 上执行一次（phpMyAdmin 或宝塔终端 mysql 客户端）。
-- 对现有微信用户无影响：username/password_hash 对他们保持 NULL。

ALTER TABLE user_info
  ADD COLUMN username      VARCHAR(64)  NULL,
  ADD COLUMN password_hash VARCHAR(255) NULL;

-- 用户名唯一索引（MySQL 允许多行 NULL，微信用户不受约束）
ALTER TABLE user_info
  ADD UNIQUE INDEX uniq_user_info_username (username);
