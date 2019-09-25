DROP PROCEDURE IF EXISTS `sp_update_sql`;

DELIMITER ;;
CREATE PROCEDURE `sp_update_sql`()
BEGIN

DECLARE lastVersion INT DEFAULT 1;
DECLARE lastVersion1 INT DEFAULT 1;
DECLARE versionNotes VARCHAR(255) DEFAULT '';

SELECT MAX(tb_database_version.version) INTO lastVersion FROM tb_database_version;
SET lastVersion = IFNULL((lastVersion),1);
SET lastVersion1 = lastVersion;

###############################################################
# 表格修改开始

-- ----------------------------
-- Table structure for tb_activites
-- ----------------------------
IF lastVersion < 2 THEN
	DROP TABLE IF EXISTS `tb_activites`;
	CREATE TABLE `tb_activites` (
		`id` int(11) NOT NULL,
		`content` longtext NOT NULL,
		`create_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  		`update_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		PRIMARY KEY (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='活动表';

	SET lastVersion = 2;
	SET versionNotes = 'add tb_activites';
END IF;

-- ----------------------------
-- Table structure for tb_zset_power
-- ----------------------------
IF lastVersion < 3 THEN
	DROP TABLE IF EXISTS `tb_zset_power`;
	CREATE TABLE `tb_zset_power` (
		`id` int(11) NOT NULL,
		`uid` bigint(20) NOT NULL,
		`score` int(11) NOT NULL,
		`create_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  		`update_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		PRIMARY KEY (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='战力排行榜';

	SET lastVersion = 3;
	SET versionNotes = 'add tb_zset_power';
END IF;

IF lastVersion < 4 THEN
	ALTER TABLE `tb_user` ADD `exp` int(11) NOT NULL;

	SET lastVersion = 4;
	SET versionNotes = 'alter tb_user';
END IF;

IF lastVersion < 5 THEN
	DROP TABLE IF EXISTS `tb_user_heros`;
	CREATE TABLE `tb_user_heros` (
		`uid` bigint(20) NOT NULL,
		`hero_id` int(11) NOT NULL,
		`level` int(11) NOT NULL,
		`create_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  		`update_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		PRIMARY KEY (`uid`, `hero_id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='英雄角色';

	SET lastVersion = 5;
	SET versionNotes = 'add tb_user_heros';
END IF;

IF lastVersion < 6 THEN
	DROP TABLE IF EXISTS `tb_user_friends`;
	CREATE TABLE `tb_user_friends` (
		`uid` bigint(20) NOT NULL,
		`friend_uid` bigint(20) NOT NULL,
		`alias` varchar(255) NOT NULL,
		`create_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  		`update_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		PRIMARY KEY (`uid`, `friend_uid`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='英雄角色';

	SET lastVersion = 6;
	SET versionNotes = 'add tb_user_friends';
END IF;

IF lastVersion < 7 THEN
	DROP TABLE IF EXISTS `tb_user_friend_reqs`;
	CREATE TABLE `tb_user_friend_reqs` (
		`id`  bigint(20) NOT NULL,
		`to_uid` bigint(20) NOT NULL,
		`from_uid` bigint(20) NOT NULL,
		`accept` int(11) NOT NULL,
		`create_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  		`update_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		PRIMARY KEY (`uid`, `friend_uid`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='英雄角色';

	SET lastVersion = 7;
	SET versionNotes = 'add tb_user_friend_reqs';
END IF;

IF lastVersion < 8 THEN
	DROP TABLE IF EXISTS `tb_teams`;
	CREATE TABLE `tb_user_friend_reqs` (
		`id`  bigint(20) NOT NULL,
		`name` varchar(32) NOT NULL,
		`simple` varchar(255) NOT NULL,
		`power` int(11) NOT NULL,
		`join_tp` int(11) NOT NULL,
		`join_cond` varchar(255) NOT NULL,
		`members` blob NOT NULL,
		`create_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  		`update_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		PRIMARY KEY (`uid`, `friend_uid`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='英雄角色';

	SET lastVersion = 8;
	SET versionNotes = 'add tb_teams';
END IF;

IF lastVersion > lastVersion1 THEN
	INSERT INTO tb_database_version(version, update_date, last_sql) values(lastVersion, now(), versionNotes);
END IF;

END;;
DELIMITER ;

call sp_update_sql();
DROP PROCEDURE IF EXISTS `sp_update_sql`;

###############################################################
# 过程修改开始

-- ----------------------------
-- Procedure structure for sp_activities_select
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_activities_select`;
DELIMITER ;;
CREATE PROCEDURE `sp_activities_select`(IN `in_id` int)
BEGIN
	SELECT * FROM tb_activites WHERE id=in_id;
END;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_activities_insert_or_update
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_activities_insert_or_update`;
DELIMITER ;;
CREATE PROCEDURE `sp_activities_insert_or_update`(IN `in_id` int, IN `in_content` longtext)
BEGIN
	INSERT INTO tb_activites(id, content)
	VALUES (in_id, in_content)
	ON DUPLICATE KEY UPDATE id=in_id, content=in_content;
END;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_user_achievement_select
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_user_achievement_select`;
DELIMITER ;;
CREATE PROCEDURE `sp_user_achievement_select`(IN `in_uid` bigint)
BEGIN
	SELECT * FROM tb_user_achievement WHERE uid=in_uid;
END;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_user_achievement_insert_or_update
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_user_achievement_insert_or_update`;
DELIMITER ;;
CREATE PROCEDURE `sp_user_achievement_insert_or_update`(IN `in_uid` bigint,
	IN `in_id` int,
	IN `in_reach` int,
	IN `in_recv` int)
BEGIN
	INSERT INTO tb_user_achievement(uid, id, reach, recv)
	VALUES (in_uid, in_id, in_reach, in_recv)
	ON DUPLICATE KEY UPDATE uid=in_uid, id=in_id, reach=in_reach, recv=in_recv;
END;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_user_insert_or_update
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_user_insert_or_update`;
DELIMITER ;;
CREATE PROCEDURE `sp_user_insert_or_update`(IN `in_uid` bigint,
	IN `in_sex` int,
	IN `in_nickname` varchar(255),
	IN `in_province` varchar(255),
	IN `in_city` varchar(255),
	IN `in_country` varchar(255),
	IN `in_headimg` longtext,
	IN `in_openid` varchar(255),
	IN `in_nameid` varchar(255),
	IN `in_login_at` int,
	IN `in_new_user` int,
	IN `in_level` int,
	IN `in_exp` int)
BEGIN
	INSERT INTO tb_user(uid, sex, nickname, province, city, country, headimg, openid, nameid, login_at, new_user, `level`, exp)
	VALUES (in_uid, 
		in_sex, 
		in_nickname, 
		in_province, 
		in_city, 
		in_country, 
		in_headimg, 
		in_openid, 
		in_nameid,
		in_login_at, 
		in_new_user, 
		in_level,
		in_exp)
	ON DUPLICATE KEY UPDATE uid=in_uid,
		sex=in_sex,
		nickname=in_nickname,
		province=in_province,
		city=in_city,
		country=in_country,
		headimg=in_headimg,
		openid=in_openid,
		nameid=in_nameid,
		login_at=in_login_at,
		new_user=in_new_user,
		`level`=in_level,
		exp=in_exp;
END;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_user_heros_select
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_user_heros_select`;
DELIMITER ;;
CREATE PROCEDURE `sp_user_heros_select`(IN `in_uid` bigint)
BEGIN
	SELECT * FROM tb_user_heros WHERE uid=in_uid;
END;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_user_heros_insert_or_update
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_user_heros_insert_or_update`;
DELIMITER ;;
CREATE PROCEDURE `sp_user_heros_insert_or_update`(IN `in_uid` bigint,
	IN `in_hero_id` int,
	IN `in_level` int)
BEGIN
	INSERT INTO tb_user_heros(uid, hero_id, level)
	VALUES (in_uid, in_hero_id, in_level)
	ON DUPLICATE KEY UPDATE uid=in_uid, id=in_hero_id, level=in_level;
END;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_zset_power_select
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_zset_power_select`;
DELIMITER ;;
CREATE PROCEDURE `sp_zset_power_select`()
BEGIN
	SELECT * FROM tb_zset_power;
END;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_zset_power_insert_or_update
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_zset_power_insert_or_update`;
DELIMITER ;;
CREATE PROCEDURE `sp_zset_power_insert_or_update`(IN `in_id` int,
	IN `in_uid` bigint,
	IN `in_power` int)
BEGIN
	INSERT INTO tb_zset_power(id, uid, power)
	VALUES (in_id, in_uid, in_power)
	ON DUPLICATE KEY UPDATE uid=in_id, power=in_power;
END;;

-- ----------------------------
-- Procedure structure for sp_user_friends_select
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_user_friends_select`;
DELIMITER ;;
CREATE PROCEDURE `sp_user_friends_select`()
BEGIN
	SELECT * FROM tb_user_friends ;
END;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_zset_power_insert_or_update
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_user_firends_insert_or_update`;
DELIMITER ;;
CREATE PROCEDURE `sp_user_firends_insert_or_update`(IN `in_uid` bigint,
	IN `in_friend_uid` bigint,
	IN `in_alias` varchar(255))
BEGIN
	INSERT INTO tb_user_friends(uid, friend_uid, alias)
	VALUES (in_uid, in_friend_uid, in_alias)
	ON DUPLICATE KEY UPDATE uid=in_uid, friend_uid=in_friend_uid, alias=in_alias;
END;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_user_friend_reqs_select
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_user_friend_reqs_select`;
DELIMITER ;;
CREATE PROCEDURE `sp_user_friend_reqs_select`(IN `in_uid` bigint)
BEGIN
	SELECT * FROM tb_user_friend_reqs WHERE to_uid=in_uid;
END;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_user_friend_reqs_insert_or_update
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_user_friend_reqs_insert_or_update`;
DELIMITER ;;
CREATE PROCEDURE `sp_user_friend_reqs_insert_or_update`(IN `in_id` bigint(20),
	IN `in_to_uid` bigint(20),
	IN `in_from_uid` bigint(20),
	IN `in_accept` int(11))
BEGIN
	INSERT INTO tb_user_friend_reqs(id, to_uid, from_uid, accept)
	VALUES (in_id, in_to_uid, in_friend_uid, in_accept)
	ON DUPLICATE KEY UPDATE id=in_id, to_uid=in_to_uid, from_uid=in_friend_uid, accept=in_accept;
END;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_teams_select
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_teams_select`;
DELIMITER ;;
CREATE PROCEDURE `sp_teams_select`()
BEGIN
	SELECT * FROM tb_teams;
END;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_teams_insert_or_update
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_teams_insert_or_update`;
DELIMITER ;;
CREATE PROCEDURE `sp_teams_insert_or_update`(IN `in_id` bigint(20),
	IN `in_name` varchar(32),
	IN `in_simple` varchar(255),
	IN `in_power` int(11),
	IN `in_join_tp` int(11),
	IN `in_join_cond` varchar(255),
	IN `in_members` blob,
BEGIN
	INSERT INTO tb_teams(id, name, simple, power, join_tp, join_cond, members)
	VALUES (in_id, in_name, in_simple, in_power, in_join_tp, in_join_cond, in_members)
	ON DUPLICATE KEY UPDATE id=in_id, name=in_name, simple=in_simple, power=in_power, join_tp=in_join_tp, join_cond=in_join_cond, members=in_members;
END;;
DELIMITER ;

# 过程修改结束
###############################################################
