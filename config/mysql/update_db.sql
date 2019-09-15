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
		`id` bigint(20) NOT NULL,
		`content` longtext NOT NULL,
		`create_at` int(11) NOT NULL,
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
		`create_at` int(11) NOT NULL,
		`update_at` int(11) NOT NULL,
		PRIMARY KEY (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='战力排行榜';

	SET lastVersion = 3;
	SET versionNotes = 'add tb_zset_power';
END IF;

IF lastVersion < 4 THEN
	ALTER TABLE `tb_activites` ADD `update_at` int(11) NOT NULL;

	SET lastVersion = 4;
	SET versionNotes = 'alter tb_activites';
END IF;

IF lastVersion < 5 THEN

	SET lastVersion = 5;
	SET versionNotes = 'test';
END IF;

IF lastVersion < 6 THEN
	ALTER TABLE `tb_user` ADD `exp` int(11) NOT NULL;

	SET lastVersion = 6;
	SET versionNotes = 'alter tb_user';
END IF;

IF lastVersion < 7 THEN
	DROP TABLE IF EXISTS `tb_user_heros`;
	CREATE TABLE `tb_user_heros` (
		`uid` bigint(20) NOT NULL,
		`hero_id` int(11) NOT NULL,
		`level` int(11) NOT NULL,
		`create_at` int(11) NOT NULL,
		`update_at` int(11) NOT NULL,
		PRIMARY KEY (`uid`, `hero_id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='英雄角色';

	SET lastVersion = 7;
	SET versionNotes = 'add tb_user_heros';
END IF;

IF lastVersion > lastVersion1 THEN
	INSERT INTO tb_database_version(version, update_date, last_sql) values(lastVersion, now(), versionNotes);
END IF;

END
;;

DELIMITER ;

call sp_update_sql();
DROP PROCEDURE IF EXISTS `sp_update_sql`;

###############################################################
# 过程修改开始

-- ----------------------------
-- Procedure structure for sp_activities_select
-- ----------------------------
DELIMITER ;
DROP PROCEDURE IF EXISTS `sp_activities_select`;
DELIMITER ;;
CREATE PROCEDURE `sp_activities_select`(IN `in_id` bigint)
BEGIN
	SELECT * FROM tb_activites WHERE id=in_id;
END;;

-- ----------------------------
-- Procedure structure for sp_activities_insert_or_update
-- ----------------------------
DELIMITER ;
DROP PROCEDURE IF EXISTS `sp_activities_insert_or_update`;
DELIMITER ;;
CREATE PROCEDURE `sp_activities_insert_or_update`(IN `in_id` bigint)
BEGIN
	SELECT * FROM tb_activites WHERE id=in_id;
END;;

-- ----------------------------
-- Procedure structure for sp_user_achievement_select
-- ----------------------------
DELIMITER ;
DROP PROCEDURE IF EXISTS `sp_user_achievement_select`;
DELIMITER ;;
CREATE PROCEDURE `sp_user_achievement_select`(IN `in_uid` bigint)
BEGIN
	SELECT * FROM tb_user_achievement WHERE uid=in_uid;
END;;

-- ----------------------------
-- Procedure structure for sp_user_achievement_insert_or_update
-- ----------------------------
DELIMITER ;
DROP PROCEDURE IF EXISTS `sp_user_achievement_insert_or_update`;
DELIMITER ;;
CREATE PROCEDURE `sp_user_achievement_insert_or_update`(IN `in_uid` bigint,
	IN `in_id` int,
	IN `in_reach` int,
	IN `in_recv` int,
	IN `in_create_at` int,
	IN `in_update_at` int)
BEGIN
	INSERT INTO tb_user_achievement(uid, id, reach, recv, create_at, update_at)
	VALUES (in_uid, in_id, in_reach, in_recv, in_create_at, in_update_at)
	ON DUPLICATE KEY UPDATE uid=in_uid, id=in_id;
END;;

-- ----------------------------
-- Procedure structure for sp_user_insert_or_update
-- ----------------------------
DELIMITER ;
DROP PROCEDURE IF EXISTS `sp_user_insert_or_update`;
DELIMITER ;;
CREATE PROCEDURE `sp_user_insert_or_update`(IN `in_uid` bigint,
	IN `in_sex` int,
	IN `in_nickname` varchar(255),
	IN `in_province` varchar(255),
	IN `in_city` varchar(255),
	IN `in_country` varchar(255),
	IN `in_headimg` varchar(255),
	IN `in_openid` varchar(255),
	IN `in_nameid` varchar(255),
	IN `in_create_at` int,
	IN `in_update_at` int,
	IN `in_login_at` int,
	IN `in_new_user` int,
	IN `in_level` int,
	IN `in_exp` int)
BEGIN
	INSERT INTO tb_user(uid, sex, nickname, province, city, country, headimg, openid, nameid, create_at, update_at, login_at, new_user, `level`, exp)
	VALUES (in_uid, 
		in_sex, 
		in_nickname, 
		in_province, 
		in_city, 
		in_country, 
		in_headimg, 
		in_openid, 
		in_nameid, 
		in_create_at, 
		in_update_at, 
		in_login_at, 
		in_new_user, 
		in_level,
		in_exp)
	ON DUPLICATE KEY UPDATE uid=in_uid;
END
;;


-- ----------------------------
-- Procedure structure for sp_user_heros_select
-- ----------------------------
DELIMITER ;
DROP PROCEDURE IF EXISTS `sp_user_heros_select`;
DELIMITER ;;
CREATE PROCEDURE `sp_user_heros_select`(IN `in_uid` bigint)
BEGIN
	SELECT * FROM tb_user_heros WHERE uid=in_uid;
END
;;

-- ----------------------------
-- Procedure structure for sp_user_heros_insert_or_update
-- ----------------------------
DELIMITER ;
DROP PROCEDURE IF EXISTS `sp_user_heros_insert_or_update`;
DELIMITER ;;
CREATE PROCEDURE `sp_user_heros_insert_or_update`(IN `in_uid` bigint,
	IN `in_hero_id` int,
	IN `in_level` int,
	IN `in_create_at` int,
	IN `in_update_at` int)
BEGIN
	INSERT INTO tb_user_heros(uid, hero_id, level, create_at, update_at)
	VALUES (in_uid, in_hero_id, in_level, in_create_at, in_update_at)
	ON DUPLICATE KEY UPDATE uid=in_uid, id=in_hero_id;
END;;

-- ----------------------------
-- Procedure structure for sp_zset_power_select
-- ----------------------------
DELIMITER ;
DROP PROCEDURE IF EXISTS `sp_zset_power_select`;
DELIMITER ;;
CREATE PROCEDURE `sp_zset_power_select`()
BEGIN
	SELECT * FROM tb_zset_power;
END
;;

-- ----------------------------
-- Procedure structure for sp_zset_power_insert_or_update
-- ----------------------------
DELIMITER ;
DROP PROCEDURE IF EXISTS `sp_zset_power_insert_or_update`;
DELIMITER ;;
CREATE PROCEDURE `sp_zset_power_insert_or_update`(IN `in_id` int,
	IN `in_uid` bigint,
	IN `in_power` int,
	IN `in_create_at` int,
	IN `in_update_at` int)
BEGIN
	INSERT INTO tb_zset_power(id, uid, power, create_at, update_at)
	VALUES (in_id, in_uid, in_power, in_create_at, in_update_at)
	ON DUPLICATE KEY UPDATE uid=in_id;
END;;

# 过程修改结束
###############################################################

