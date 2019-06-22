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

IF lastVersion > lastVersion1 THEN
	INSERT INTO tb_database_version(version, update_date, last_sql) values(lastVersion, now(), versionNotes);
END IF;
END;;
DELIMITER ;
call sp_update_sql();
DROP PROCEDURE IF EXISTS `sp_update_sql`;

###############################################################
# 过程修改开始

DELIMITER ;;

-- ----------------------------
-- Procedure structure for sp_activities_select
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_activities_select`;
CREATE PROCEDURE `sp_activities_select`(IN `in_id` bigint)
BEGIN
	SELECT * FROM tb_activites WHERE id=in_id;
END;;

-- ----------------------------
-- Procedure structure for sp_activities_select
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_zset_power_select`;
CREATE PROCEDURE `sp_zset_power_select`(IN `in_id` bigint)
BEGIN
	SELECT * FROM tb_activites WHERE id=in_id;
END;;

###############################################################
# 过程修改结束

DELIMITER ;