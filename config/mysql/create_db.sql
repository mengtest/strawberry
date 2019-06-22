/*
Navicat MySQL Data Transfer

Source Server         : mysql
Source Server Version : 50711
Source Host           : localhost:3306
Source Database       : dezhou

Target Server Type    : MYSQL
Target Server Version : 50711
File Encoding         : 65001

Date: 2018-07-05 11:39:08
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for tb_account
-- ----------------------------
DROP TABLE IF EXISTS `tb_account`;
CREATE TABLE `tb_account` (
  `username` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `uid` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`username`),
  UNIQUE KEY `uid` (`uid`) USING HASH
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for tb_nameid
-- ----------------------------
DROP TABLE IF EXISTS `tb_nameid`;
CREATE TABLE `tb_nameid` (
  `nameid` varchar(255) NOT NULL,
  `uid` int(11) NOT NULL,
  PRIMARY KEY (`nameid`),
  UNIQUE KEY `uid_UNIQUE` (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for tb_openid
-- ----------------------------
DROP TABLE IF EXISTS `tb_openid`;
CREATE TABLE `tb_openid` (
  `openid` varchar(255) NOT NULL,
  `uid` int(11) NOT NULL,
  PRIMARY KEY (`openid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for tb_record
-- ----------------------------
DROP TABLE IF EXISTS `tb_record`;
CREATE TABLE `tb_record` (
  `id` bigint(18) NOT NULL,
  `content` longtext NOT NULL,
  `datetime` int(11) NOT NULL,
  `idx1` int(11) NOT NULL,
  `idx2` int(11) NOT NULL,
  `idx3` int(11) NOT NULL,
  `idx4` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for tb_room
-- ----------------------------
DROP TABLE IF EXISTS `tb_room`;
CREATE TABLE `tb_room` (
  `id` int(11) NOT NULL,
  `type` int(11) NOT NULL,
  `mode` int(11) NOT NULL,
  `host` bigint(20) NOT NULL,
  `open` int(11) NOT NULL,
  `rule` varchar(255) NOT NULL,
  `create_at` int(11) NOT NULL,
  `update_at` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for tb_room_mgr_rooms
-- ----------------------------
DROP TABLE IF EXISTS `tb_room_mgr_rooms`;
CREATE TABLE `tb_room_mgr_rooms` (
  `id` int(11) NOT NULL,
  `type` int(11) NOT NULL,
  `mode` int(11) NOT NULL,
  `host` bigint(20) NOT NULL,
  `users` varchar(255) NOT NULL,
  `ju` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for tb_room_mgr_users
-- ----------------------------
DROP TABLE IF EXISTS `tb_room_mgr_users`;
CREATE TABLE `tb_room_mgr_users` (
  `uid` bigint(18) NOT NULL,
  `roomid` int(11) NOT NULL,
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for tb_room_users
-- ----------------------------
DROP TABLE IF EXISTS `tb_room_users`;
CREATE TABLE `tb_room_users` (
  `uid` bigint(20) NOT NULL,
  `roomid` int(11) NOT NULL,
  `state` varchar(255) NOT NULL,
  `idx` int(11) NOT NULL,
  `chip` int(11) NOT NULL,
  PRIMARY KEY (`uid`, `roomid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for tb_sysmail
-- ----------------------------
DROP TABLE IF EXISTS `tb_sysmail`;
CREATE TABLE `tb_sysmail` (
  `id` bigint(20) NOT NULL,
  `to` bigint(20) NOT NULL,
  `from` bigint(20) NOT NULL,
  `title` varchar(255) NOT NULL,
  `content` text NOT NULL,
  `datetime` int(11) NOT NULL,
  `addon` varchar(255) NOT NULL,
  `create_at` int(11) NOT NULL,
  `update_at` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for tb_user
-- ----------------------------
DROP TABLE IF EXISTS `tb_user`;
CREATE TABLE `tb_user` (
  `uid` bigint(20) NOT NULL,
  `sex` int(11) NOT NULL,
  `nickname` varchar(255) NOT NULL,
  `province` varchar(255) NOT NULL,
  `city` varchar(255) NOT NULL,
  `country` varchar(255) NOT NULL,
  `headimg` longtext NOT NULL,
  `openid` varchar(255) NOT NULL,
  `nameid` varchar(255) NOT NULL,
  `create_at` int(11) NOT NULL,
  `update_at` int(11) NOT NULL,
  `login_at` int(11) NOT NULL,
  `new_user` int(11) NOT NULL,
  `level` int(11) NOT NULL,
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for tb_user_achievement
-- ----------------------------
DROP TABLE IF EXISTS `tb_user_achievement`;
CREATE TABLE `tb_user_achievement` (
  `uid` bigint(10) NOT NULL,
  `id` int(10) NOT NULL,
  `reach` int(10) NOT NULL,
  `recv` int(10) NOT NULL,
  `create_at` int(11) NOT NULL,
  `update_at` int(11) NOT NULL,
  PRIMARY KEY (`id`,`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for tb_user_checkindaily
-- ----------------------------
DROP TABLE IF EXISTS `tb_user_checkindaily`;
CREATE TABLE `tb_user_checkindaily` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) NOT NULL,
  `month` int(11) NOT NULL,
  `count` int(11) NOT NULL,
  `day` int(11) NOT NULL,
  `create_at` int(11) DEFAULT NULL,
  `update_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`,`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for tb_user_funcopen
-- ----------------------------
DROP TABLE IF EXISTS `tb_user_funcopen`;
CREATE TABLE `tb_user_funcopen` (
  `uid` bigint(20) NOT NULL,
  `id` int(11) NOT NULL,
  `open` int(11) DEFAULT NULL,
  `create_at` int(11) DEFAULT NULL,
  `update_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`uid`,`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for tb_user_inbox
-- ----------------------------
DROP TABLE IF EXISTS `tb_user_inbox`;
CREATE TABLE `tb_user_inbox` (
  `uid` bigint(20) NOT NULL,
  `id` bigint(20) NOT NULL,
  `to` bigint(20) NOT NULL,
  `from` bigint(20) NOT NULL,
  `title` varchar(255) NOT NULL,
  `content` longtext NOT NULL,
  `datetime` int(11) NOT NULL,
  `readed` int(11) NOT NULL,
  `addon` varchar(255) NOT NULL,
  `create_at` int(11) NOT NULL,
  `update_at` int(11) NOT NULL,
  PRIMARY KEY (`id`,`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for tb_user_outbox
-- ----------------------------
DROP TABLE IF EXISTS `tb_user_outbox`;
CREATE TABLE `tb_user_outbox` (
  `uid` bigint(20) NOT NULL,
  `id` bigint(20) NOT NULL,
  `from` bigint(20) NOT NULL,
  `to` bigint(20) NOT NULL,
  `title` varchar(255) NOT NULL,
  `content` varchar(255) NOT NULL,
  `datetime` int(11) NOT NULL,
  `addon` varchar(255) NOT NULL,
  `create_at` int(11) NOT NULL,
  `update_at` int(11) NOT NULL,
  PRIMARY KEY (`uid`,`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for tb_user_package
-- ----------------------------
DROP TABLE IF EXISTS `tb_user_package`;
CREATE TABLE `tb_user_package` (
  `uid` bigint(20) NOT NULL,
  `id` int(11) NOT NULL,
  `num` int(11) DEFAULT NULL,
  `create_at` int(11) DEFAULT NULL,
  `update_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`uid`,`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for tb_user_record
-- ----------------------------
DROP TABLE IF EXISTS `tb_user_record`;
CREATE TABLE `tb_user_record` (
  `uid` bigint(11) NOT NULL,
  `id` bigint(11) NOT NULL,
  `recordid` int(11) NOT NULL,
  PRIMARY KEY (`id`,`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for tb_user_room
-- ----------------------------
DROP TABLE IF EXISTS `tb_user_room`;
CREATE TABLE `tb_user_room` (
  `uid` bigint(20) NOT NULL,
  `roomid` int(11) DEFAULT NULL,
  `type` int(11) NOT NULL,
  `mode` int(11) DEFAULT NULL,
  `created` int(11) DEFAULT NULL,
  `joined` int(11) DEFAULT NULL,
  `create_at` int(11) DEFAULT NULL,
  `update_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for tb_user_task
-- ----------------------------
DROP TABLE IF EXISTS `tb_user_task`;
CREATE TABLE `tb_user_task` (
  `uid` bigint(11) NOT NULL,
  `id` bigint(10) NOT NULL,
  `rech` int(11) DEFAULT NULL,
  `recv` int(11) DEFAULT NULL,
  `create_at` int(11) DEFAULT NULL,
  `update_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`,`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for tb_database_version
-- ----------------------------
DROP TABLE IF EXISTS `tb_database_version`;
CREATE TABLE `tb_database_version` (
  `version` INT(11) NOT NULL,
  `update_date` datetime NOT NULL,
  `last_sql` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for tb_user_room_mahjong
-- ----------------------------
DROP TABLE IF EXISTS `tb_user_room_mahjong`;
CREATE TABLE `tb_user_room_mahjong` (
  `uid` bigint(20) NOT NULL,
  `roomid` int(11) NOT NULL,
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Procedure structure for sp_account_select
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_account_select`;
DELIMITER ;;
CREATE PROCEDURE `sp_account_select`(IN `in_username` varchar(64),IN `in_password` varchar(64))
BEGIN
	#Routine body goes here...
	SELECT * FROM tb_account WHERE username=in_username AND `password`=in_password;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_account_insert_or_update
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_account_insert_or_update`;
DELIMITER ;;
CREATE PROCEDURE `sp_account_insert_or_update`(IN `in_username` varchar(64),IN `in_password` varchar(64), IN `in_uid` bigint(20))
BEGIN
	# Routine body goes here...
  INSERT INTO tb_account(username, password, uid)
	VALUES (in_username, in_password, in_uid)
	ON DUPLICATE KEY UPDATE username=in_username, password=in_password, uid=in_uid;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_offuser_room_update_created
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_offuser_room_update_created`;
DELIMITER ;;
CREATE PROCEDURE `sp_offuser_room_update_created`(IN `in_uid` bigint,IN `in_created` int,IN `in_joined` int,IN `in_update_at` int,IN `in_mode` int)
BEGIN
	#Routine body goes here...
	UPDATE tb_user_room 
	SET created=in_created,
			joined=in_joined,
			update_at=in_update_at,
			`mode`=in_mode
	WHERE uid=in_uid;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_room_insert_or_update
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_room_insert_or_update`;
DELIMITER ;;
CREATE PROCEDURE `sp_room_insert_or_update`(IN `in_id` int,
  IN `in_type` int, 
  IN `in_mode` int,
  IN `in_host` bigint,
  IN `in_open` int,
  IN `in_rule` varchar(255),
  IN `in_create_at` int,
  IN `in_update_at` int)
BEGIN
	# Routine body goes here...
	INSERT INTO tb_room(id, type, mode, `host`, `open`, rule, create_at, update_at)
	VALUES (in_id, in_type, in_mode, in_host, in_open, in_rule, in_create_at, in_update_at)
	ON DUPLICATE KEY UPDATE id=in_id, 
    type=in_type, 
    mode=in_mode, 
    `host`=in_host, 
    `open`=in_open, 
    rule=in_rule,
    create_at=in_create_at,
    update_at=in_update_at;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_room_mgr_rooms_insert_or_update
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_room_mgr_rooms_insert_or_update`;
DELIMITER ;;
CREATE PROCEDURE `sp_room_mgr_rooms_insert_or_update`(IN `in_id` int,
  IN `in_host` bigint,
  IN `in_users` varchar(255), 
  IN `in_ju` int, 
  IN `in_mode` int,
  IN `in_type` int)
BEGIN
	-- Routine body goes here...
	INSERT INTO tb_room_mgr_rooms(id, `host`, users, ju, mode, `type`)
	VALUES (in_id, in_host, in_users, in_ju, in_mode,  in_type)
	ON DUPLICATE KEY UPDATE id=in_id, 
    `host`=in_host, 
    users=in_users, 
    ju=in_ju, 
    mode=in_mode,
    `type`=in_type;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_room_mgr_rooms_select
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_room_mgr_rooms_select`;
DELIMITER ;;
CREATE PROCEDURE `sp_room_mgr_rooms_select`()
BEGIN
	-- Routine body goes here...
  SELECT * FROM tb_room_mgr_rooms;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_room_mgr_users_insert_or_update
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_room_mgr_users_insert_or_update`;
DELIMITER ;;
CREATE PROCEDURE `sp_room_mgr_users_insert_or_update`(IN `in_uid` bigint,IN `in_roomid` int)
BEGIN
	-- Routine body goes here...
	INSERT INTO tb_room_mgr_users(uid, roomid)
	VALUES (in_uid, in_roomid)
	ON DUPLICATE KEY UPDATE uid=in_uid, roomid=in_roomid;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_room_mgr_users_select
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_room_mgr_users_select`;
DELIMITER ;;
CREATE PROCEDURE `sp_room_mgr_users_select`()
BEGIN
	-- Routine body goes here...
	SELECT * FROM tb_room_mgr_users;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_room_select
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_room_select`;
DELIMITER ;;
CREATE PROCEDURE `sp_room_select`(IN `in_id` int)
BEGIN
	-- Routine body goes here...
	SELECT * FROM tb_room WHERE id=in_id;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_room_users_insert_or_update
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_room_users_insert_or_update`;
DELIMITER ;;
CREATE PROCEDURE `sp_room_users_insert_or_update`(IN `in_uid` bigint,IN `in_roomid` int,IN `in_state` varchar(200), IN `in_idx` int, IN `in_chip` int)
BEGIN
	#Routine body goes here...
	INSERT INTO tb_room_users(uid, roomid, state, idx, chip)
	VALUES (in_uid, in_roomid, in_state, in_idx, in_chip)
	ON DUPLICATE KEY UPDATE uid=in_uid, roomid=in_roomid, state=in_state, idx=in_idx, chip=in_chip;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_room_users_select
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_room_users_select`;
DELIMITER ;;
CREATE PROCEDURE `sp_room_users_select`(IN `in_roomid` int)
BEGIN
	#Routine body goes here...
	SELECT * FROM tb_room_users WHERE roomid=in_roomid;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_sysmail_select
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_sysmail_select`;
DELIMITER ;;
CREATE PROCEDURE `sp_sysmail_select`()
BEGIN
	-- Routine body goes here...
	SELECT * FROM tb_sysmail;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_user_funcopen_insert_or_update
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_user_funcopen_insert_or_update`;
DELIMITER ;;
CREATE PROCEDURE `sp_user_funcopen_insert_or_update`(IN `in_uid` bigint,IN `in_id` int,IN `in_open` int,IN `in_create_at` int,IN `in_update_at` int)
BEGIN
	-- Routine body goes here...
	INSERT INTO tb_user_funcopen(uid, id, `open`, create_at, update_at)
	VALUES (in_uid, in_id, in_open, in_create_at, in_update_at)
	ON DUPLICATE KEY UPDATE uid=in_uid, id=in_id, `open`=in_open, create_at=in_create_at, update_at=in_update_at;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_user_funcopen_select
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_user_funcopen_select`;
DELIMITER ;;
CREATE PROCEDURE `sp_user_funcopen_select`(IN `in_uid` bigint)
BEGIN
	-- Routine body goes here...
	SELECT * FROM tb_user_funcopen WHERE uid=in_uid;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_user_insert_or_update
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_user_insert_or_update`;
DELIMITER ;;
CREATE PROCEDURE `sp_user_insert_or_update`(IN `in_uid` bigint,IN `in_sex` int,IN `in_nickname` varchar(255),IN `in_province` varchar(255),IN `in_city` varchar(255),IN `in_country` varchar(255),IN `in_headimg` varchar(255),IN `in_openid` varchar(255),IN `in_nameid` varchar(255),IN `in_create_at` int,IN `in_update_at` int,IN `in_login_at` int,IN `in_new_user` int,IN `in_level` int)
BEGIN
	#Routine body goes here...
	INSERT INTO tb_user(uid, sex, nickname, province, city, country, headimg, openid, nameid, create_at, update_at, login_at, new_user, `level`)
	VALUES (in_uid, in_sex, in_nickname, in_province, in_city, in_country, in_headimg, in_openid, in_nameid, in_create_at, in_update_at, in_login_at, in_new_user, in_level)
	ON DUPLICATE KEY UPDATE uid=in_uid, sex=in_sex,
		nickname=in_nickname, province=in_province, city=in_city, country=in_country, headimg=in_headimg,
		openid=in_openid, nameid=in_nameid, create_at=in_create_at, update_at=in_update_at, login_at=in_login_at, new_user=in_new_user,
		`level`=in_level;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_user_package_insert_or_update
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_user_package_insert_or_update`;
DELIMITER ;;
CREATE PROCEDURE `sp_user_package_insert_or_update`(IN `in_uid` bigint,IN `in_id` int,IN `in_num` int,IN `in_create_at` int,IN `in_update_at` int)
BEGIN
	#Routine body goes here...
	INSERT INTO tb_user_package(uid, id, num, create_at, update_at)
	VALUES (in_uid, in_id, in_num, in_create_at, in_update_at)
	ON DUPLICATE KEY UPDATE uid=in_uid, id=in_id, num=in_num, create_at=in_create_at, update_at=in_update_at;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_user_package_select
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_user_package_select`;
DELIMITER ;;
CREATE PROCEDURE `sp_user_package_select`(IN `in_uid` bigint)
BEGIN
	#Routine body goes here...
	SELECT * FROM tb_user_package WHERE uid=in_uid;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_user_room_insert_or_update
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_user_room_insert_or_update`;
DELIMITER ;;
CREATE PROCEDURE `sp_user_room_insert_or_update`(IN `in_uid` bigint,IN `in_roomid` int,IN `in_created` int,IN `in_joined` int,IN `in_create_at` int,IN `in_update_at` int,IN `in_mode` int,IN `in_type` int)
BEGIN
	# Routine body goes here...
	INSERT INTO tb_user_room(uid, roomid, created, joined, create_at, update_at, `mode`, `type`)
	VALUES (in_uid, in_roomid, in_created, in_joined, in_create_at, in_update_at, in_mode, in_type)
	ON DUPLICATE KEY UPDATE uid=in_uid, roomid=in_roomid, created=in_created, joined=in_joined,
	create_at=in_create_at, update_at=in_update_at, `mode`=in_mode, `type`=in_type;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_user_room_select
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_user_room_select`;
DELIMITER ;;
CREATE PROCEDURE `sp_user_room_select`(IN `in_uid` bigint)
BEGIN
	#Routine body goes here...
	SELECT * FROM tb_user_room WHERE uid=in_uid;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_user_select
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_user_select`;
DELIMITER ;;
CREATE PROCEDURE `sp_user_select`(IN `in_uid` bigint)
BEGIN
	-- Routine body goes here...
	SELECT * FROM tb_user WHERE uid=in_uid;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_user_room_mahjong_select
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_user_room_mahjong_select`;
DELIMITER ;;
CREATE PROCEDURE `sp_user_room_mahjong_select`(IN `in_uid` bigint)
BEGIN
	-- Routine body goes here...
	SELECT * FROM tb_user_room_mahjong WHERE uid=in_uid;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_user_room_mahjong_insert_or_update
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_user_room_mahjong_insert_or_update`;
DELIMITER ;;
CREATE PROCEDURE `sp_user_room_mahjong_insert_or_update`(IN `in_uid` bigint,IN `in_roomid` int)
BEGIN
	INSERT INTO tb_user_room_mahjong(uid, roomid)
	VALUES (in_uid, in_roomid)
	ON DUPLICATE KEY UPDATE uid=in_uid, roomid=in_roomid;
END
;;
DELIMITER ;