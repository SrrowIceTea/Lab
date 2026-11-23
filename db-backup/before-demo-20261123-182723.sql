-- MySQL dump 10.13  Distrib 8.0.46, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: userservice
-- ------------------------------------------------------
-- Server version	8.0.46

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `userservice`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `userservice` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `userservice`;

--
-- Table structure for table `class`
--

DROP TABLE IF EXISTS `class`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `class` (
  `class_id` bigint NOT NULL AUTO_INCREMENT,
  `admin_id` bigint DEFAULT NULL,
  `class_detail` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `class_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_end` int DEFAULT '0',
  PRIMARY KEY (`class_id`),
  UNIQUE KEY `uk_class_name` (`class_name`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `class`
--

LOCK TABLES `class` WRITE;
/*!40000 ALTER TABLE `class` DISABLE KEYS */;
INSERT INTO `class` VALUES (1,NULL,'用户服务本地登录默认班级','网络安全232班',0);
/*!40000 ALTER TABLE `class` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `course`
--

DROP TABLE IF EXISTS `course`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `course` (
  `id` int NOT NULL AUTO_INCREMENT,
  `cost_time` int DEFAULT NULL,
  `course_description` varchar(1024) COLLATE utf8mb4_unicode_ci NOT NULL,
  `difficulty` int DEFAULT NULL,
  `image_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `instructor` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_by` bigint DEFAULT NULL,
  `course_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `schedule` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `course_status` tinyint DEFAULT '1',
  `tags` longtext COLLATE utf8mb4_unicode_ci,
  `type` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_course_status_type` (`course_status`,`type`),
  KEY `idx_course_creator_status` (`created_by`,`course_status`),
  CONSTRAINT `fk_course_creator` FOREIGN KEY (`created_by`) REFERENCES `user` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `course`
--

LOCK TABLES `course` WRITE;
/*!40000 ALTER TABLE `course` DISABLE KEYS */;
INSERT INTO `course` VALUES (1,NULL,'介绍网络安全基本概念、常见威胁与实验环境使用规范。',1,'a9fe8e50-ba21-45ef-abd5-50b717857502-course-sql-injection.png','李伟',NULL,'网络安全导论',NULL,1,'[\"安全基础\",\"实验规范\"]','网络安全基础'),(2,NULL,'结合靶场理解 SQL 注入的形成原因、利用方式与参数化查询防护。',2,'a9fe8e50-ba21-45ef-abd5-50b717857502-course-sql-injection.png','李伟',NULL,'SQL 注入原理与防护',NULL,1,'[\"SQL注入\",\"Web安全\"]','Web安全'),(3,NULL,'通过反射型与存储型 XSS 实验学习输入输出编码和内容安全策略。',2,'eb678908-4878-4303-94ae-b3434d52612a-course-xss-deep-dive.png','李伟',NULL,'跨站脚本攻击与防护',NULL,1,'[\"XSS\",\"Web安全\"]','Web安全'),(4,NULL,'分析不安全上传校验、文件解析差异和安全存储策略。',3,'5780e906-42a1-4a88-ad06-d054bbf92735-3.png','李伟',NULL,'文件上传漏洞',NULL,1,'[\"文件上传\",\"Web安全\"]','Web安全'),(5,NULL,'学习目录遍历漏洞成因、路径规范化处理与最小权限配置。',2,NULL,'李伟',NULL,'目录遍历漏洞',NULL,1,'[\"目录遍历\",\"访问控制\"]','Web安全'),(6,NULL,'通过命令拼接案例理解系统命令注入及白名单防护。',3,NULL,'李伟',NULL,'命令注入漏洞',NULL,1,'[\"命令注入\",\"系统安全\"]','系统安全'),(7,NULL,'理解跨站请求伪造攻击流程，并实践令牌校验和 SameSite 防护。',2,NULL,'李伟',NULL,'CSRF 攻击与防护',NULL,1,'[\"CSRF\",\"Web安全\"]','Web安全'),(8,NULL,'综合运用信息收集、漏洞定位、利用验证和修复说明完成阶段实训。',4,NULL,'李伟',NULL,'Web 安全综合实训',NULL,1,'[\"综合实训\",\"漏洞分析\"]','综合实践');
/*!40000 ALTER TABLE `course` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `learning_event`
--

DROP TABLE IF EXISTS `learning_event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `learning_event` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `ai_message` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `command` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `course_id` bigint DEFAULT NULL,
  `created_at` datetime(6) DEFAULT NULL,
  `duration_seconds` int DEFAULT NULL,
  `error_message` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `event_type` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `lab_id` bigint DEFAULT NULL,
  `metadata` json DEFAULT NULL,
  `module_id` bigint DEFAULT NULL,
  `occurred_at` datetime(6) DEFAULT NULL,
  `question_id` bigint DEFAULT NULL,
  `score` int DEFAULT NULL,
  `success` bit(1) DEFAULT NULL,
  `user_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `learning_event`
--

LOCK TABLES `learning_event` WRITE;
/*!40000 ALTER TABLE `learning_event` DISABLE KEYS */;
/*!40000 ALTER TABLE `learning_event` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `module`
--

DROP TABLE IF EXISTS `module`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `module` (
  `module_id` int NOT NULL AUTO_INCREMENT,
  `difficulty` int DEFAULT NULL,
  `image_id` int DEFAULT NULL,
  `introduction` varchar(1024) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `module_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `task_points` longtext COLLATE utf8mb4_unicode_ci,
  `type` longtext COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`module_id`),
  KEY `idx_module_difficulty` (`difficulty`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `module`
--

LOCK TABLES `module` WRITE;
/*!40000 ALTER TABLE `module` DISABLE KEYS */;
INSERT INTO `module` VALUES (1,3,101,'在靶场中完成 SQL 注入定位、验证和参数化修复。','SQL 注入基础实验',NULL,'[\"SQL注入\",\"Web安全\"]'),(2,2,102,'完成 XSS 与 CSRF 攻击验证并比较不同防护方式。','XSS 与 CSRF 基础实验',NULL,'[\"XSS\",\"CSRF\",\"Web安全\"]'),(3,3,103,'分析上传校验缺陷并给出后端校验与隔离建议。','文件上传安全实验',NULL,'[\"文件上传\",\"Web安全\"]');
/*!40000 ALTER TABLE `module` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `module_course`
--

DROP TABLE IF EXISTS `module_course`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `module_course` (
  `module_id` int NOT NULL,
  `course_id` int NOT NULL,
  PRIMARY KEY (`module_id`,`course_id`),
  KEY `idx_module_course_course` (`course_id`),
  CONSTRAINT `fk_module_course_course` FOREIGN KEY (`course_id`) REFERENCES `course` (`id`),
  CONSTRAINT `fk_module_course_module` FOREIGN KEY (`module_id`) REFERENCES `module` (`module_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `module_course`
--

LOCK TABLES `module_course` WRITE;
/*!40000 ALTER TABLE `module_course` DISABLE KEYS */;
INSERT INTO `module_course` VALUES (1,2),(2,3),(3,4);
/*!40000 ALTER TABLE `module_course` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `student_profile_snapshot`
--

DROP TABLE IF EXISTS `student_profile_snapshot`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_profile_snapshot` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `ai_collaboration` double DEFAULT NULL,
  `badges` json DEFAULT NULL,
  `created_at` datetime(6) DEFAULT NULL,
  `engagement` double DEFAULT NULL,
  `evidence` json DEFAULT NULL,
  `exploration` double DEFAULT NULL,
  `knowledge_mastery` double DEFAULT NULL,
  `overall_score` double DEFAULT NULL,
  `recommendations` json DEFAULT NULL,
  `summary` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `troubleshooting` double DEFAULT NULL,
  `updated_at` datetime(6) DEFAULT NULL,
  `user_id` bigint DEFAULT NULL,
  `weaknesses` json DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `student_profile_snapshot`
--

LOCK TABLES `student_profile_snapshot` WRITE;
/*!40000 ALTER TABLE `student_profile_snapshot` DISABLE KEYS */;
/*!40000 ALTER TABLE `student_profile_snapshot` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `teaching_class`
--

DROP TABLE IF EXISTS `teaching_class`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teaching_class` (
  `teaching_class_id` bigint NOT NULL AUTO_INCREMENT,
  `class_name` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `academic_year` varchar(9) COLLATE utf8mb4_unicode_ci NOT NULL,
  `semester` int NOT NULL,
  `teacher_id` bigint NOT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `status` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ACTIVE',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`teaching_class_id`),
  UNIQUE KEY `uk_teacher_term_class_name` (`teacher_id`,`academic_year`,`semester`,`class_name`),
  KEY `idx_teaching_class_teacher_status` (`teacher_id`,`status`),
  KEY `idx_teaching_class_term_status` (`academic_year`,`semester`,`status`),
  CONSTRAINT `fk_teaching_class_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `user` (`user_id`),
  CONSTRAINT `chk_teaching_class_dates` CHECK (((`start_date` is null) or (`end_date` is null) or (`end_date` >= `start_date`))),
  CONSTRAINT `chk_teaching_class_semester` CHECK ((`semester` in (1,2))),
  CONSTRAINT `chk_teaching_class_status` CHECK ((`status` in (_utf8mb4'ACTIVE',_utf8mb4'ARCHIVED')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `teaching_class`
--

LOCK TABLES `teaching_class` WRITE;
/*!40000 ALTER TABLE `teaching_class` DISABLE KEYS */;
/*!40000 ALTER TABLE `teaching_class` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `teaching_class_course`
--

DROP TABLE IF EXISTS `teaching_class_course`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teaching_class_course` (
  `teaching_class_course_id` bigint NOT NULL AUTO_INCREMENT,
  `teaching_class_id` bigint NOT NULL,
  `course_id` int NOT NULL,
  `teaching_order` int NOT NULL,
  `planned_start_date` date DEFAULT NULL,
  `planned_end_date` date DEFAULT NULL,
  `teaching_content` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`teaching_class_course_id`),
  UNIQUE KEY `uk_teaching_class_course` (`teaching_class_id`,`course_id`),
  UNIQUE KEY `uk_teaching_class_order` (`teaching_class_id`,`teaching_order`),
  KEY `idx_teaching_class_course_course` (`course_id`,`teaching_class_id`),
  CONSTRAINT `fk_teaching_class_course_class` FOREIGN KEY (`teaching_class_id`) REFERENCES `teaching_class` (`teaching_class_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_teaching_class_course_course` FOREIGN KEY (`course_id`) REFERENCES `course` (`id`),
  CONSTRAINT `chk_teaching_class_course_dates` CHECK (((`planned_start_date` is null) or (`planned_end_date` is null) or (`planned_end_date` >= `planned_start_date`))),
  CONSTRAINT `chk_teaching_class_course_order` CHECK ((`teaching_order` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `teaching_class_course`
--

LOCK TABLES `teaching_class_course` WRITE;
/*!40000 ALTER TABLE `teaching_class_course` DISABLE KEYS */;
/*!40000 ALTER TABLE `teaching_class_course` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `teaching_class_import_batch`
--

DROP TABLE IF EXISTS `teaching_class_import_batch`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teaching_class_import_batch` (
  `import_batch_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `teaching_class_id` bigint NOT NULL,
  `teacher_id` bigint NOT NULL,
  `file_sha256` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `preview_json` json NOT NULL,
  `confirmed_result_json` json DEFAULT NULL,
  `status` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PREVIEWED',
  `expires_at` datetime(6) NOT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `confirmed_at` datetime(6) DEFAULT NULL,
  PRIMARY KEY (`import_batch_id`),
  KEY `idx_import_batch_class_status` (`teaching_class_id`,`status`,`expires_at`),
  KEY `idx_import_batch_teacher_created` (`teacher_id`,`created_at`),
  CONSTRAINT `fk_import_batch_class` FOREIGN KEY (`teaching_class_id`) REFERENCES `teaching_class` (`teaching_class_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_import_batch_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `user` (`user_id`),
  CONSTRAINT `chk_import_batch_status` CHECK ((`status` in (_utf8mb4'PREVIEWED',_utf8mb4'CONFIRMED',_utf8mb4'EXPIRED')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `teaching_class_import_batch`
--

LOCK TABLES `teaching_class_import_batch` WRITE;
/*!40000 ALTER TABLE `teaching_class_import_batch` DISABLE KEYS */;
/*!40000 ALTER TABLE `teaching_class_import_batch` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `teaching_class_student`
--

DROP TABLE IF EXISTS `teaching_class_student`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teaching_class_student` (
  `teaching_class_id` bigint NOT NULL,
  `student_id` bigint NOT NULL,
  `source` varchar(24) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'EXCEL_IMPORT',
  `joined_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`teaching_class_id`,`student_id`),
  KEY `idx_teaching_class_student_user` (`student_id`,`teaching_class_id`),
  CONSTRAINT `fk_teaching_class_student_class` FOREIGN KEY (`teaching_class_id`) REFERENCES `teaching_class` (`teaching_class_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_teaching_class_student_user` FOREIGN KEY (`student_id`) REFERENCES `user` (`user_id`),
  CONSTRAINT `chk_teaching_class_student_source` CHECK ((`source` in (_utf8mb4'EXCEL_IMPORT',_utf8mb4'MANUAL')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `teaching_class_student`
--

LOCK TABLES `teaching_class_student` WRITE;
/*!40000 ALTER TABLE `teaching_class_student` DISABLE KEYS */;
/*!40000 ALTER TABLE `teaching_class_student` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user` (
  `user_id` bigint NOT NULL AUTO_INCREMENT,
  `create_time` datetime(6) DEFAULT CURRENT_TIMESTAMP(6),
  `is_admin` bit(1) DEFAULT b'0',
  `user_role` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'STUDENT',
  `is_deleted` int DEFAULT '0',
  `user_academy` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_email` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_gender` int DEFAULT NULL,
  `user_image` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_student_number` varchar(13) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_tel` varchar(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `class_id_class_id` bigint NOT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `uk_user_student_number` (`user_student_number`),
  KEY `idx_user_class_id` (`class_id_class_id`),
  KEY `idx_user_role_deleted` (`user_role`,`is_deleted`),
  CONSTRAINT `fk_user_class` FOREIGN KEY (`class_id_class_id`) REFERENCES `class` (`class_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user`
--

LOCK TABLES `user` WRITE;
/*!40000 ALTER TABLE `user` DISABLE KEYS */;
INSERT INTO `user` VALUES (1,'2026-11-18 20:03:27.904731',_binary '','TEACHER',0,'网络安全学院','liwei@seclab.edu.cn',1,NULL,'李伟','$2a$10$7Bjo883FABcmxt7J.QLaTu3o4gQOypxAyMMChMaBXSqdADS9xTSWC','T20260001','13800138000',1),(2,'2026-11-18 20:14:00.127047',_binary '\0','STUDENT',0,NULL,NULL,1,NULL,'学生123456','$2b$10$te/QF92vEJZI/OXE0wu6B.MZ1tjOKr4JoL3Tgr0X1p5.tqObQ3mj.','123456',NULL,1);
/*!40000 ALTER TABLE `user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Current Database: `seclab_profile`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `seclab_profile` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `seclab_profile`;

--
-- Table structure for table `ai_context_injection`
--

DROP TABLE IF EXISTS `ai_context_injection`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ai_context_injection` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `conversation_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `message_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `context_type` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `context_summary` text COLLATE utf8mb4_unicode_ci,
  `context_size` int NOT NULL DEFAULT '0',
  `raw_context_json` json DEFAULT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_ai_context_conversation_time` (`conversation_id`,`created_at`),
  KEY `idx_ai_context_message` (`message_id`),
  CONSTRAINT `fk_ai_context_conversation` FOREIGN KEY (`conversation_id`) REFERENCES `ai_conversation` (`conversation_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ai_context_message` FOREIGN KEY (`message_id`) REFERENCES `ai_message` (`message_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ai_context_injection`
--

LOCK TABLES `ai_context_injection` WRITE;
/*!40000 ALTER TABLE `ai_context_injection` DISABLE KEYS */;
/*!40000 ALTER TABLE `ai_context_injection` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ai_conversation`
--

DROP TABLE IF EXISTS `ai_conversation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ai_conversation` (
  `conversation_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` bigint DEFAULT NULL,
  `class_id` bigint DEFAULT NULL,
  `course_id` bigint DEFAULT NULL,
  `module_id` bigint DEFAULT NULL,
  `task_id` bigint DEFAULT NULL,
  `question_id` bigint DEFAULT NULL,
  `lab_session_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `dify_conversation_id` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'active',
  `source` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ai-agent-service',
  `start_time` datetime(6) NOT NULL,
  `last_message_at` datetime(6) NOT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`conversation_id`),
  UNIQUE KEY `uk_ai_conversation_dify_id` (`dify_conversation_id`),
  KEY `idx_ai_conversation_user_time` (`user_id`,`last_message_at`),
  KEY `idx_ai_conversation_module_time` (`module_id`,`last_message_at`),
  KEY `idx_ai_conversation_lab_session` (`lab_session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ai_conversation`
--

LOCK TABLES `ai_conversation` WRITE;
/*!40000 ALTER TABLE `ai_conversation` DISABLE KEYS */;
INSERT INTO `ai_conversation` VALUES ('conv-1a8af5d7-e525-468a-ad3e-c44b4e945e91',NULL,NULL,1,1,NULL,NULL,'ai-practice-1-1795007401013','ai-practice-1-1795007401013','active','frontend','2026-11-18 13:10:36.962237','2026-11-18 13:10:36.962237','2026-11-18 21:10:36.963900','2026-11-18 21:10:36.963900'),('conv-284cd480-47d5-4b9e-abe3-e75ba28ffb3d',NULL,NULL,1,1,NULL,NULL,'ai-practice-1-1795005962614','ai-practice-1-1795005962614','active','frontend','2026-11-18 12:46:18.972512','2026-11-18 12:46:28.829012','2026-11-18 20:46:18.994975','2026-11-18 20:46:28.842533'),('conv-96b2ebb5-2e04-4f0d-a8dd-6b0d0765eade',NULL,NULL,1,1,NULL,NULL,'ai-practice-1-1795006033351','ai-practice-1-1795006033351','active','frontend','2026-11-18 12:50:35.530787','2026-11-18 12:50:35.530787','2026-11-18 20:50:35.533405','2026-11-18 20:50:35.533405'),('conv-9ee5ef59-74d0-4730-9805-bec3c983d959',NULL,NULL,1,1,NULL,NULL,'ai-practice-1-1795429333898','ai-practice-1-1795429333898','active','frontend','2026-11-23 10:23:04.461910','2026-11-23 10:23:04.461910','2026-11-23 18:23:04.479774','2026-11-23 18:23:04.479774');
/*!40000 ALTER TABLE `ai_conversation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ai_message`
--

DROP TABLE IF EXISTS `ai_message`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ai_message` (
  `message_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `conversation_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `content` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `content_length` int NOT NULL DEFAULT '0',
  `token_count` int DEFAULT NULL,
  `event_name` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `hint_level` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `contains_context` tinyint(1) NOT NULL DEFAULT '0',
  `contains_error_excerpt` tinyint(1) NOT NULL DEFAULT '0',
  `raw_payload_json` json DEFAULT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`message_id`),
  KEY `idx_ai_message_conversation_time` (`conversation_id`,`created_at`),
  KEY `idx_ai_message_role_time` (`role`,`created_at`),
  CONSTRAINT `fk_ai_message_conversation` FOREIGN KEY (`conversation_id`) REFERENCES `ai_conversation` (`conversation_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ai_message`
--

LOCK TABLES `ai_message` WRITE;
/*!40000 ALTER TABLE `ai_message` DISABLE KEYS */;
/*!40000 ALTER TABLE `ai_message` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ai_tool_call`
--

DROP TABLE IF EXISTS `ai_tool_call`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ai_tool_call` (
  `tool_call_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `conversation_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `message_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tool_name` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tool_input_json` json DEFAULT NULL,
  `tool_output_json` json DEFAULT NULL,
  `status` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'unknown',
  `error_message` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`tool_call_id`),
  KEY `idx_ai_tool_call_conversation_time` (`conversation_id`,`created_at`),
  KEY `idx_ai_tool_call_message` (`message_id`),
  KEY `idx_ai_tool_call_tool` (`tool_name`),
  CONSTRAINT `fk_ai_tool_call_conversation` FOREIGN KEY (`conversation_id`) REFERENCES `ai_conversation` (`conversation_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ai_tool_call_message` FOREIGN KEY (`message_id`) REFERENCES `ai_message` (`message_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ai_tool_call`
--

LOCK TABLES `ai_tool_call` WRITE;
/*!40000 ALTER TABLE `ai_tool_call` DISABLE KEYS */;
/*!40000 ALTER TABLE `ai_tool_call` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `challenge_completion_event`
--

DROP TABLE IF EXISTS `challenge_completion_event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `challenge_completion_event` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint DEFAULT NULL,
  `class_id` bigint DEFAULT NULL,
  `course_id` bigint DEFAULT NULL,
  `module_id` bigint DEFAULT NULL,
  `task_id` bigint DEFAULT NULL,
  `lab_session_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `completion_status` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `total_time_seconds` int DEFAULT NULL,
  `total_ai_ask_count` int NOT NULL DEFAULT '0',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_completion_user_time` (`user_id`,`created_at`),
  KEY `idx_completion_session` (`lab_session_id`),
  KEY `idx_completion_module_time` (`module_id`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `challenge_completion_event`
--

LOCK TABLES `challenge_completion_event` WRITE;
/*!40000 ALTER TABLE `challenge_completion_event` DISABLE KEYS */;
/*!40000 ALTER TABLE `challenge_completion_event` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `class_profile_snapshot`
--

DROP TABLE IF EXISTS `class_profile_snapshot`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `class_profile_snapshot` (
  `snapshot_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `class_id` bigint NOT NULL,
  `course_id` bigint DEFAULT NULL,
  `computed_at` datetime(6) NOT NULL,
  `student_count` int NOT NULL DEFAULT '0',
  `class_avg_knowledge_mastery` decimal(5,2) NOT NULL DEFAULT '0.00',
  `class_avg_troubleshooting` decimal(5,2) NOT NULL DEFAULT '0.00',
  `class_avg_autonomy` decimal(5,2) NOT NULL DEFAULT '0.00',
  `class_avg_ai_collaboration` decimal(5,2) NOT NULL DEFAULT '0.00',
  `class_avg_engagement` decimal(5,2) NOT NULL DEFAULT '0.00',
  `class_overall_score` decimal(5,2) NOT NULL DEFAULT '0.00',
  `weak_dimensions_json` json NOT NULL,
  `strengths_json` json NOT NULL,
  `risk_students_json` json NOT NULL,
  `summary_json` json NOT NULL,
  `source_range_start` datetime(6) DEFAULT NULL,
  `source_range_end` datetime(6) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`snapshot_id`),
  KEY `idx_class_profile_class_time` (`class_id`,`computed_at`),
  KEY `idx_class_profile_course_time` (`course_id`,`computed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `class_profile_snapshot`
--

LOCK TABLES `class_profile_snapshot` WRITE;
/*!40000 ALTER TABLE `class_profile_snapshot` DISABLE KEYS */;
/*!40000 ALTER TABLE `class_profile_snapshot` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `class_profile_student_metric`
--

DROP TABLE IF EXISTS `class_profile_student_metric`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `class_profile_student_metric` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `class_id` bigint NOT NULL,
  `user_id` bigint NOT NULL,
  `snapshot_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `overall_score` decimal(5,2) NOT NULL DEFAULT '0.00',
  `knowledge_mastery_score` decimal(5,2) NOT NULL DEFAULT '0.00',
  `troubleshooting_score` decimal(5,2) NOT NULL DEFAULT '0.00',
  `autonomy_score` decimal(5,2) NOT NULL DEFAULT '0.00',
  `ai_collaboration_score` decimal(5,2) NOT NULL DEFAULT '0.00',
  `engagement_score` decimal(5,2) NOT NULL DEFAULT '0.00',
  `risk_level` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'low',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_class_profile_metric_snapshot_user` (`snapshot_id`,`user_id`),
  KEY `idx_class_profile_metric_class_user` (`class_id`,`user_id`),
  KEY `idx_class_profile_metric_snapshot` (`snapshot_id`),
  KEY `idx_class_profile_metric_risk` (`class_id`,`risk_level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `class_profile_student_metric`
--

LOCK TABLES `class_profile_student_metric` WRITE;
/*!40000 ALTER TABLE `class_profile_student_metric` DISABLE KEYS */;
/*!40000 ALTER TABLE `class_profile_student_metric` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `container_command_event`
--

DROP TABLE IF EXISTS `container_command_event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `container_command_event` (
  `command_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `lab_session_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_id` bigint DEFAULT NULL,
  `class_id` bigint DEFAULT NULL,
  `course_id` bigint DEFAULT NULL,
  `module_id` bigint DEFAULT NULL,
  `task_id` bigint DEFAULT NULL,
  `container_name` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `command` varchar(2048) COLLATE utf8mb4_unicode_ci NOT NULL,
  `normalized_command` varchar(2048) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cmd_category` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'other',
  `cwd` varchar(1024) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `exit_code` int DEFAULT NULL,
  `duration_ms` int DEFAULT NULL,
  `output_digest` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `source` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'hook',
  `request_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `executed_at` datetime(6) NOT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`command_id`),
  KEY `idx_container_command_session_time` (`lab_session_id`,`executed_at`),
  KEY `idx_container_command_user_time` (`user_id`,`executed_at`),
  KEY `idx_container_command_module_time` (`module_id`,`executed_at`),
  KEY `idx_container_command_container_time` (`container_name`,`executed_at`),
  KEY `idx_container_command_category_time` (`cmd_category`,`executed_at`),
  KEY `idx_container_command_request_id` (`request_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `container_command_event`
--

LOCK TABLES `container_command_event` WRITE;
/*!40000 ALTER TABLE `container_command_event` DISABLE KEYS */;
/*!40000 ALTER TABLE `container_command_event` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `container_file_event`
--

DROP TABLE IF EXISTS `container_file_event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `container_file_event` (
  `file_event_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `lab_session_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_id` bigint DEFAULT NULL,
  `class_id` bigint DEFAULT NULL,
  `course_id` bigint DEFAULT NULL,
  `module_id` bigint DEFAULT NULL,
  `task_id` bigint DEFAULT NULL,
  `container_name` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `file_path` varchar(2048) COLLATE utf8mb4_unicode_ci NOT NULL,
  `file_ext` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `action` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `size_before` bigint DEFAULT NULL,
  `size_after` bigint DEFAULT NULL,
  `sha256` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_key_file` tinyint(1) NOT NULL DEFAULT '0',
  `source` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'watcher',
  `request_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `changed_at` datetime(6) NOT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`file_event_id`),
  KEY `idx_container_file_session_time` (`lab_session_id`,`changed_at`),
  KEY `idx_container_file_user_time` (`user_id`,`changed_at`),
  KEY `idx_container_file_module_time` (`module_id`,`changed_at`),
  KEY `idx_container_file_container_time` (`container_name`,`changed_at`),
  KEY `idx_container_file_action_time` (`action`,`changed_at`),
  KEY `idx_container_file_request_id` (`request_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `container_file_event`
--

LOCK TABLES `container_file_event` WRITE;
/*!40000 ALTER TABLE `container_file_event` DISABLE KEYS */;
/*!40000 ALTER TABLE `container_file_event` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `error_event`
--

DROP TABLE IF EXISTS `error_event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `error_event` (
  `error_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `lab_session_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_id` bigint DEFAULT NULL,
  `class_id` bigint DEFAULT NULL,
  `course_id` bigint DEFAULT NULL,
  `module_id` bigint DEFAULT NULL,
  `task_id` bigint DEFAULT NULL,
  `container_name` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `command_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `error_signature` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `error_category` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `raw_excerpt` varchar(1024) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `severity` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'low',
  `source` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'api',
  `request_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `occurred_at` datetime(6) NOT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`error_id`),
  KEY `idx_error_event_session_time` (`lab_session_id`,`occurred_at`),
  KEY `idx_error_event_user_time` (`user_id`,`occurred_at`),
  KEY `idx_error_event_module_time` (`module_id`,`occurred_at`),
  KEY `idx_error_event_command` (`command_id`),
  KEY `idx_error_event_signature_time` (`error_signature`,`occurred_at`),
  KEY `idx_error_event_category_time` (`error_category`,`occurred_at`),
  KEY `idx_error_event_request_id` (`request_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `error_event`
--

LOCK TABLES `error_event` WRITE;
/*!40000 ALTER TABLE `error_event` DISABLE KEYS */;
/*!40000 ALTER TABLE `error_event` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `flag_submission`
--

DROP TABLE IF EXISTS `flag_submission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `flag_submission` (
  `submission_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` bigint DEFAULT NULL,
  `class_id` bigint DEFAULT NULL,
  `course_id` bigint DEFAULT NULL,
  `module_id` bigint DEFAULT NULL,
  `task_id` bigint DEFAULT NULL,
  `lab_session_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `container_name` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `flag_text` varchar(512) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_correct` tinyint(1) NOT NULL DEFAULT '0',
  `score` decimal(8,2) NOT NULL DEFAULT '0.00',
  `request_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`submission_id`),
  KEY `idx_flag_submission_user_time` (`user_id`,`created_at`),
  KEY `idx_flag_submission_session_time` (`lab_session_id`,`created_at`),
  KEY `idx_flag_submission_module_time` (`module_id`,`created_at`),
  KEY `idx_flag_submission_request_id` (`request_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `flag_submission`
--

LOCK TABLES `flag_submission` WRITE;
/*!40000 ALTER TABLE `flag_submission` DISABLE KEYS */;
/*!40000 ALTER TABLE `flag_submission` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `generated_question`
--

DROP TABLE IF EXISTS `generated_question`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `generated_question` (
  `generated_question_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `question_numeric_id` bigint NOT NULL,
  `training_session_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `question_type` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `knowledge_point_id` bigint DEFAULT NULL,
  `module_id` bigint DEFAULT NULL,
  `task_id` bigint DEFAULT NULL,
  `difficulty` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `stem` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `options_json` json DEFAULT NULL,
  `standard_answer` text COLLATE utf8mb4_unicode_ci,
  `reference_answer` text COLLATE utf8mb4_unicode_ci,
  `explanation` text COLLATE utf8mb4_unicode_ci,
  `scoring_rubric_json` json DEFAULT NULL,
  `source_model` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `raw_ai_json` json DEFAULT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`generated_question_id`),
  UNIQUE KEY `uk_generated_question_numeric` (`question_numeric_id`),
  KEY `idx_generated_question_session` (`training_session_id`),
  KEY `idx_generated_question_kp` (`knowledge_point_id`),
  KEY `idx_generated_question_module_task` (`module_id`,`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `generated_question`
--

LOCK TABLES `generated_question` WRITE;
/*!40000 ALTER TABLE `generated_question` DISABLE KEYS */;
/*!40000 ALTER TABLE `generated_question` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `generated_question_attempt`
--

DROP TABLE IF EXISTS `generated_question_attempt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `generated_question_attempt` (
  `attempt_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `training_session_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `generated_question_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` bigint NOT NULL,
  `answer_json` json NOT NULL,
  `is_correct` tinyint(1) DEFAULT NULL,
  `score` decimal(8,2) NOT NULL DEFAULT '0.00',
  `cost_time` int DEFAULT NULL,
  `submission_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `profile_rebuild_snapshot_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `submitted_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`attempt_id`),
  KEY `idx_generated_attempt_session` (`training_session_id`,`submitted_at`),
  KEY `idx_generated_attempt_question` (`generated_question_id`,`submitted_at`),
  KEY `idx_generated_attempt_user_time` (`user_id`,`submitted_at`),
  KEY `idx_generated_attempt_submission` (`submission_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `generated_question_attempt`
--

LOCK TABLES `generated_question_attempt` WRITE;
/*!40000 ALTER TABLE `generated_question_attempt` DISABLE KEYS */;
/*!40000 ALTER TABLE `generated_question_attempt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `guidance_proactive_notes`
--

DROP TABLE IF EXISTS `guidance_proactive_notes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `guidance_proactive_notes` (
  `note_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '主动提示记录 ID（gnote-{uuid}）',
  `lab_session_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '靶机会话 ID，关联 lab_session',
  `user_id` bigint DEFAULT NULL COMMENT '学生 ID，便于按学生查历史',
  `signal_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'docker-service 触发的 signal ID',
  `conversation_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '本地 ai_conversation ID（guidance-{lab_session_id}）',
  `message_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '本地 ai_message ID（msg-{uuid}）',
  `trigger_reason` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '触发原因：repeated_error / stuck_loop / repeated_command 等',
  `ai_message` longtext COLLATE utf8mb4_unicode_ci COMMENT 'Dify 生成的完整启发式诊断文本',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '落库时间',
  PRIMARY KEY (`note_id`),
  KEY `idx_guidance_note_session_time` (`lab_session_id`,`created_at`),
  KEY `idx_guidance_note_user_time` (`user_id`,`created_at`),
  KEY `idx_guidance_note_signal` (`signal_id`),
  KEY `idx_guidance_note_conversation` (`conversation_id`),
  KEY `idx_guidance_note_message` (`message_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `guidance_proactive_notes`
--

LOCK TABLES `guidance_proactive_notes` WRITE;
/*!40000 ALTER TABLE `guidance_proactive_notes` DISABLE KEYS */;
/*!40000 ALTER TABLE `guidance_proactive_notes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `knowledge_point`
--

DROP TABLE IF EXISTS `knowledge_point`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `knowledge_point` (
  `knowledge_point_id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `category` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `difficulty_level` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`knowledge_point_id`),
  KEY `idx_knowledge_point_category` (`category`),
  KEY `idx_knowledge_point_active` (`is_active`)
) ENGINE=InnoDB AUTO_INCREMENT=602 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `knowledge_point`
--

LOCK TABLES `knowledge_point` WRITE;
/*!40000 ALTER TABLE `knowledge_point` DISABLE KEYS */;
INSERT INTO `knowledge_point` VALUES (101,'SQL注入联合查询列数判断','SQL注入','通过ORDER BY、UNION SELECT等方式判断字段数和回显位。','medium',1,'2026-11-18 20:03:23.058031'),(102,'SQL盲注与时间延迟判断','SQL注入','通过布尔条件或sleep延迟推断数据库内容。','medium',1,'2026-11-18 20:03:23.058031'),(201,'XSS输入输出上下文判断','XSS','识别HTML、属性、脚本等上下文并选择合适payload。','easy',1,'2026-11-18 20:03:23.058031'),(301,'CSRF Token校验与请求伪造','CSRF','理解跨站请求伪造、Token绑定和Referer校验。','medium',1,'2026-11-18 20:03:23.058031'),(401,'无空格命令执行绕过','命令执行','使用IFS、变量替换、重定向等方式替代空格完成命令拼接。','medium',1,'2026-11-18 20:03:23.058031'),(402,'命令执行黑名单字符绕过','命令执行','针对过滤规则使用编码、拼接、环境变量或通配符绕过。','hard',1,'2026-11-18 20:03:23.058031'),(501,'文件上传类型校验绕过','文件上传','围绕后缀、MIME、Content-Type和解析差异构造上传绕过。','medium',1,'2026-11-18 20:03:23.058031'),(601,'目录遍历路径规范化绕过','目录遍历','理解../、编码、绝对路径和路径归一化绕过。','medium',1,'2026-11-18 20:03:23.058031');
/*!40000 ALTER TABLE `knowledge_point` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lab_session`
--

DROP TABLE IF EXISTS `lab_session`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `lab_session` (
  `session_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` bigint DEFAULT NULL,
  `class_id` bigint DEFAULT NULL,
  `course_id` bigint DEFAULT NULL,
  `module_id` bigint DEFAULT NULL,
  `task_id` bigint DEFAULT NULL,
  `container_name` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `container_id` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `target_url` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'running',
  `start_time` datetime(6) NOT NULL,
  `end_time` datetime(6) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`session_id`),
  KEY `idx_lab_session_user_time` (`user_id`,`start_time`),
  KEY `idx_lab_session_module_time` (`module_id`,`start_time`),
  KEY `idx_lab_session_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lab_session`
--

LOCK TABLES `lab_session` WRITE;
/*!40000 ALTER TABLE `lab_session` DISABLE KEYS */;
/*!40000 ALTER TABLE `lab_session` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `learning_event`
--

DROP TABLE IF EXISTS `learning_event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `learning_event` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `event_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` bigint DEFAULT NULL,
  `class_id` bigint DEFAULT NULL,
  `course_id` bigint DEFAULT NULL,
  `module_id` bigint DEFAULT NULL,
  `task_id` bigint DEFAULT NULL,
  `question_id` bigint DEFAULT NULL,
  `lab_session_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `event_type` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `event_time` datetime(6) NOT NULL,
  `payload_json` json NOT NULL,
  `source` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ai-agent-service',
  `request_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_learning_event_event_id` (`event_id`),
  KEY `idx_learning_event_user_time` (`user_id`,`event_time`),
  KEY `idx_learning_event_module_time` (`module_id`,`event_time`),
  KEY `idx_learning_event_lab_session_time` (`lab_session_id`,`event_time`),
  KEY `idx_learning_event_type_time` (`event_type`,`event_time`),
  KEY `idx_learning_event_request_id` (`request_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `learning_event`
--

LOCK TABLES `learning_event` WRITE;
/*!40000 ALTER TABLE `learning_event` DISABLE KEYS */;
INSERT INTO `learning_event` VALUES (1,'evt-ai-1795005978898-dltj6l8n',NULL,NULL,1,1,NULL,NULL,'ai-practice-1-1795005962614','AI_INTERACTION','2026-11-18 12:46:18.898000','{\"cwd\": null, \"extra\": null, \"score\": null, \"action\": null, \"answer\": null, \"sha256\": null, \"source\": \"frontend\", \"command\": null, \"task_id\": null, \"user_id\": null, \"class_id\": null, \"event_id\": \"evt-ai-1795005978898-dltj6l8n\", \"file_ext\": null, \"severity\": null, \"cost_time\": null, \"course_id\": 1, \"exit_code\": null, \"file_path\": null, \"flag_text\": null, \"module_id\": 1, \"command_id\": null, \"event_time\": \"2026-11-18T12:46:18.898Z\", \"event_type\": \"AI_INTERACTION\", \"is_correct\": null, \"request_id\": \"req-ai-1795005978898-uk91w2jz\", \"session_id\": null, \"size_after\": null, \"target_url\": null, \"duration_ms\": null, \"is_key_file\": null, \"message_ids\": [], \"question_id\": null, \"raw_excerpt\": null, \"size_before\": null, \"container_id\": null, \"output_digest\": null, \"question_type\": null, \"container_name\": null, \"error_category\": null, \"lab_session_id\": \"ai-practice-1-1795005962614\", \"question_score\": null, \"conversation_id\": \"conv-284cd480-47d5-4b9e-abe3-e75ba28ffb3d\", \"error_signature\": null, \"standard_answer\": null, \"context_injection_id\": null}','frontend','req-ai-1795005978898-uk91w2jz','2026-11-18 20:46:19.025344'),(2,'evt-ai-1795005988823-h96yxxvy',NULL,NULL,1,1,NULL,NULL,'ai-practice-1-1795005962614','AI_INTERACTION','2026-11-18 12:46:28.823000','{\"cwd\": null, \"extra\": null, \"score\": null, \"action\": null, \"answer\": null, \"sha256\": null, \"source\": \"frontend\", \"command\": null, \"task_id\": null, \"user_id\": null, \"class_id\": null, \"event_id\": \"evt-ai-1795005988823-h96yxxvy\", \"file_ext\": null, \"severity\": null, \"cost_time\": null, \"course_id\": 1, \"exit_code\": null, \"file_path\": null, \"flag_text\": null, \"module_id\": 1, \"command_id\": null, \"event_time\": \"2026-11-18T12:46:28.823Z\", \"event_type\": \"AI_INTERACTION\", \"is_correct\": null, \"request_id\": \"req-ai-1795005988823-isinbujv\", \"session_id\": null, \"size_after\": null, \"target_url\": null, \"duration_ms\": null, \"is_key_file\": null, \"message_ids\": [], \"question_id\": null, \"raw_excerpt\": null, \"size_before\": null, \"container_id\": null, \"output_digest\": null, \"question_type\": null, \"container_name\": null, \"error_category\": null, \"lab_session_id\": \"ai-practice-1-1795005962614\", \"question_score\": null, \"conversation_id\": \"conv-284cd480-47d5-4b9e-abe3-e75ba28ffb3d\", \"error_signature\": null, \"standard_answer\": null, \"context_injection_id\": null}','frontend','req-ai-1795005988823-isinbujv','2026-11-18 20:46:28.872987'),(3,'evt-ai-1795006235524-fax3fawm',NULL,NULL,1,1,NULL,NULL,'ai-practice-1-1795006033351','AI_INTERACTION','2026-11-18 12:50:35.524000','{\"cwd\": null, \"extra\": null, \"score\": null, \"action\": null, \"answer\": null, \"sha256\": null, \"source\": \"frontend\", \"command\": null, \"task_id\": null, \"user_id\": null, \"class_id\": null, \"event_id\": \"evt-ai-1795006235524-fax3fawm\", \"file_ext\": null, \"severity\": null, \"cost_time\": null, \"course_id\": 1, \"exit_code\": null, \"file_path\": null, \"flag_text\": null, \"module_id\": 1, \"command_id\": null, \"event_time\": \"2026-11-18T12:50:35.524Z\", \"event_type\": \"AI_INTERACTION\", \"is_correct\": null, \"request_id\": \"req-ai-1795006235524-4f8013m6\", \"session_id\": null, \"size_after\": null, \"target_url\": null, \"duration_ms\": null, \"is_key_file\": null, \"message_ids\": [], \"question_id\": null, \"raw_excerpt\": null, \"size_before\": null, \"container_id\": null, \"output_digest\": null, \"question_type\": null, \"container_name\": null, \"error_category\": null, \"lab_session_id\": \"ai-practice-1-1795006033351\", \"question_score\": null, \"conversation_id\": \"conv-96b2ebb5-2e04-4f0d-a8dd-6b0d0765eade\", \"error_signature\": null, \"standard_answer\": null, \"context_injection_id\": null}','frontend','req-ai-1795006235524-4f8013m6','2026-11-18 20:50:35.545325'),(4,'evt-ai-1795007436948-oxbr3aby',NULL,NULL,1,1,NULL,NULL,'ai-practice-1-1795007401013','AI_INTERACTION','2026-11-18 13:10:36.948000','{\"cwd\": null, \"extra\": null, \"score\": null, \"action\": null, \"answer\": null, \"sha256\": null, \"source\": \"frontend\", \"command\": null, \"task_id\": null, \"user_id\": null, \"class_id\": null, \"event_id\": \"evt-ai-1795007436948-oxbr3aby\", \"file_ext\": null, \"severity\": null, \"cost_time\": null, \"course_id\": 1, \"exit_code\": null, \"file_path\": null, \"flag_text\": null, \"module_id\": 1, \"command_id\": null, \"event_time\": \"2026-11-18T13:10:36.948Z\", \"event_type\": \"AI_INTERACTION\", \"is_correct\": null, \"request_id\": \"req-ai-1795007436948-rzamp24t\", \"session_id\": null, \"size_after\": null, \"target_url\": null, \"duration_ms\": null, \"is_key_file\": null, \"message_ids\": [], \"question_id\": null, \"raw_excerpt\": null, \"size_before\": null, \"container_id\": null, \"output_digest\": null, \"question_type\": null, \"container_name\": null, \"error_category\": null, \"lab_session_id\": \"ai-practice-1-1795007401013\", \"question_score\": null, \"conversation_id\": \"conv-1a8af5d7-e525-468a-ad3e-c44b4e945e91\", \"error_signature\": null, \"standard_answer\": null, \"context_injection_id\": null}','frontend','req-ai-1795007436948-rzamp24t','2026-11-18 21:10:36.985968'),(5,'evt-ai-1795429384345-6jhavgcd',NULL,NULL,1,1,NULL,NULL,'ai-practice-1-1795429333898','AI_INTERACTION','2026-11-23 10:23:04.345000','{\"cwd\": null, \"extra\": null, \"score\": null, \"action\": null, \"answer\": null, \"sha256\": null, \"source\": \"frontend\", \"command\": null, \"task_id\": null, \"user_id\": null, \"class_id\": null, \"event_id\": \"evt-ai-1795429384345-6jhavgcd\", \"file_ext\": null, \"severity\": null, \"cost_time\": null, \"course_id\": 1, \"exit_code\": null, \"file_path\": null, \"flag_text\": null, \"module_id\": 1, \"command_id\": null, \"event_time\": \"2026-11-23T10:23:04.345Z\", \"event_type\": \"AI_INTERACTION\", \"is_correct\": null, \"request_id\": \"req-ai-1795429384345-jfpaub08\", \"session_id\": null, \"size_after\": null, \"target_url\": null, \"duration_ms\": null, \"is_key_file\": null, \"message_ids\": [], \"question_id\": null, \"raw_excerpt\": null, \"size_before\": null, \"container_id\": null, \"output_digest\": null, \"question_type\": null, \"container_name\": null, \"error_category\": null, \"lab_session_id\": \"ai-practice-1-1795429333898\", \"question_score\": null, \"conversation_id\": \"conv-9ee5ef59-74d0-4730-9805-bec3c983d959\", \"error_signature\": null, \"standard_answer\": null, \"context_injection_id\": null}','frontend','req-ai-1795429384345-jfpaub08','2026-11-23 18:23:04.505243');
/*!40000 ALTER TABLE `learning_event` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `module_knowledge_point`
--

DROP TABLE IF EXISTS `module_knowledge_point`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `module_knowledge_point` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `module_id` bigint NOT NULL,
  `knowledge_point_id` bigint NOT NULL,
  `relevance_weight` decimal(5,2) NOT NULL DEFAULT '1.00',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_module_knowledge_point` (`module_id`,`knowledge_point_id`),
  KEY `idx_module_kp_module` (`module_id`),
  KEY `idx_module_kp_kp` (`knowledge_point_id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `module_knowledge_point`
--

LOCK TABLES `module_knowledge_point` WRITE;
/*!40000 ALTER TABLE `module_knowledge_point` DISABLE KEYS */;
INSERT INTO `module_knowledge_point` VALUES (1,1,101,1.00,'2026-11-18 20:03:23.064680'),(2,1,102,1.00,'2026-11-18 20:03:23.064680'),(3,2,201,1.00,'2026-11-18 20:03:23.064680'),(4,3,301,1.00,'2026-11-18 20:03:23.064680'),(5,4,401,1.00,'2026-11-18 20:03:23.064680'),(6,4,402,1.00,'2026-11-18 20:03:23.064680'),(7,5,501,1.00,'2026-11-18 20:03:23.064680'),(8,6,601,1.00,'2026-11-18 20:03:23.064680');
/*!40000 ALTER TABLE `module_knowledge_point` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `operation_session`
--

DROP TABLE IF EXISTS `operation_session`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `operation_session` (
  `session_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` bigint NOT NULL,
  `module_id` bigint DEFAULT NULL,
  `course_id` bigint DEFAULT NULL,
  `container_name` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  `network_name` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  `target_containers` json NOT NULL,
  `vnc_host` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '127.0.0.1',
  `vnc_port` int NOT NULL,
  `status` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'running',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`session_id`),
  KEY `idx_operation_session_user` (`user_id`),
  KEY `idx_operation_session_status_created` (`status`,`created_at`),
  KEY `idx_operation_session_module_user` (`module_id`,`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `operation_session`
--

LOCK TABLES `operation_session` WRITE;
/*!40000 ALTER TABLE `operation_session` DISABLE KEYS */;
/*!40000 ALTER TABLE `operation_session` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `question_knowledge_point`
--

DROP TABLE IF EXISTS `question_knowledge_point`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `question_knowledge_point` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `question_id` bigint DEFAULT NULL,
  `question_uid` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `generated_question_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `knowledge_point_id` bigint NOT NULL,
  `relevance_weight` decimal(5,2) NOT NULL DEFAULT '1.00',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_question_kp_question_id` (`question_id`),
  KEY `idx_question_kp_question_uid` (`question_uid`),
  KEY `idx_question_kp_generated` (`generated_question_id`),
  KEY `idx_question_kp_kp` (`knowledge_point_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `question_knowledge_point`
--

LOCK TABLES `question_knowledge_point` WRITE;
/*!40000 ALTER TABLE `question_knowledge_point` DISABLE KEYS */;
/*!40000 ALTER TABLE `question_knowledge_point` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `question_submission`
--

DROP TABLE IF EXISTS `question_submission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `question_submission` (
  `submission_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` bigint DEFAULT NULL,
  `class_id` bigint DEFAULT NULL,
  `course_id` bigint DEFAULT NULL,
  `module_id` bigint DEFAULT NULL,
  `task_id` bigint DEFAULT NULL,
  `question_id` bigint NOT NULL,
  `question_uid` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `question_type` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `answer_json` json NOT NULL,
  `standard_answer_json` json DEFAULT NULL,
  `question_snapshot_json` json DEFAULT NULL,
  `is_correct` tinyint(1) DEFAULT NULL,
  `score` decimal(8,2) NOT NULL DEFAULT '0.00',
  `cost_time` int DEFAULT NULL,
  `question_source` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'course_question',
  `training_session_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `knowledge_point_id` bigint DEFAULT NULL,
  `request_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`submission_id`),
  KEY `idx_question_submission_user_time` (`user_id`,`created_at`),
  KEY `idx_question_submission_module_time` (`module_id`,`created_at`),
  KEY `idx_question_submission_question_time` (`question_id`,`created_at`),
  KEY `idx_question_submission_uid` (`question_uid`),
  KEY `idx_question_submission_training` (`training_session_id`,`created_at`),
  KEY `idx_question_submission_kp_time` (`knowledge_point_id`,`created_at`),
  KEY `idx_question_submission_source_time` (`question_source`,`created_at`),
  KEY `idx_question_submission_request_id` (`request_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `question_submission`
--

LOCK TABLES `question_submission` WRITE;
/*!40000 ALTER TABLE `question_submission` DISABLE KEYS */;
/*!40000 ALTER TABLE `question_submission` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `student_profile_feature_daily`
--

DROP TABLE IF EXISTS `student_profile_feature_daily`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_profile_feature_daily` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `stat_date` date NOT NULL,
  `question_submit_count` int NOT NULL DEFAULT '0',
  `question_correct_count` int NOT NULL DEFAULT '0',
  `flag_submit_count` int NOT NULL DEFAULT '0',
  `flag_correct_count` int NOT NULL DEFAULT '0',
  `lab_session_count` int NOT NULL DEFAULT '0',
  `completed_lab_count` int NOT NULL DEFAULT '0',
  `ai_message_count` int NOT NULL DEFAULT '0',
  `ai_user_message_count` int NOT NULL DEFAULT '0',
  `ai_assistant_message_count` int NOT NULL DEFAULT '0',
  `command_count` int NOT NULL DEFAULT '0',
  `unique_command_count` int NOT NULL DEFAULT '0',
  `file_change_count` int NOT NULL DEFAULT '0',
  `error_count` int NOT NULL DEFAULT '0',
  `high_severity_error_count` int NOT NULL DEFAULT '0',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_profile_feature_user_date` (`user_id`,`stat_date`),
  KEY `idx_profile_feature_user_date` (`user_id`,`stat_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `student_profile_feature_daily`
--

LOCK TABLES `student_profile_feature_daily` WRITE;
/*!40000 ALTER TABLE `student_profile_feature_daily` DISABLE KEYS */;
/*!40000 ALTER TABLE `student_profile_feature_daily` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `student_profile_snapshot`
--

DROP TABLE IF EXISTS `student_profile_snapshot`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_profile_snapshot` (
  `snapshot_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` bigint NOT NULL,
  `class_id` bigint DEFAULT NULL,
  `course_id` bigint DEFAULT NULL,
  `computed_at` datetime(6) NOT NULL,
  `knowledge_mastery_score` decimal(5,2) NOT NULL DEFAULT '0.00',
  `troubleshooting_score` decimal(5,2) NOT NULL DEFAULT '0.00',
  `autonomy_score` decimal(5,2) NOT NULL DEFAULT '0.00',
  `ai_collaboration_score` decimal(5,2) NOT NULL DEFAULT '0.00',
  `engagement_score` decimal(5,2) NOT NULL DEFAULT '0.00',
  `overall_score` decimal(5,2) NOT NULL DEFAULT '0.00',
  `profile_summary_json` json NOT NULL,
  `source_range_start` datetime(6) DEFAULT NULL,
  `source_range_end` datetime(6) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`snapshot_id`),
  KEY `idx_student_profile_user_time` (`user_id`,`computed_at`),
  KEY `idx_student_profile_class_time` (`class_id`,`computed_at`),
  KEY `idx_student_profile_course_time` (`course_id`,`computed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `student_profile_snapshot`
--

LOCK TABLES `student_profile_snapshot` WRITE;
/*!40000 ALTER TABLE `student_profile_snapshot` DISABLE KEYS */;
INSERT INTO `student_profile_snapshot` VALUES ('profile-72186516-6ff3-48e8-ac30-9daca77837e4',2,NULL,NULL,'2026-11-18 12:53:23.856239',0.00,0.00,0.00,60.00,0.00,9.00,'{\"evidence\": {\"aiAskCount\": 0, \"eventCount\": 0, \"labStartCount\": 0, \"activeDayCount\": 0, \"flagSubmitCount\": 0, \"aiInteractionCount\": 0, \"questionSubmitCount\": 0}, \"raw_stats\": {\"error_count\": 0, \"event_count\": 0, \"ai_ask_count\": 0, \"command_count\": 0, \"active_day_count\": 0, \"ai_message_count\": 0, \"file_change_count\": 0, \"flag_submit_count\": 0, \"lab_session_count\": 0, \"flag_correct_count\": 0, \"completed_lab_count\": 0, \"ai_interaction_count\": 0, \"unique_command_count\": 0, \"ai_user_message_count\": 0, \"question_submit_count\": 0, \"question_correct_count\": 0, \"ai_context_message_count\": 0, \"low_severity_error_count\": 0, \"high_severity_error_count\": 0, \"ai_assistant_message_count\": 0, \"ai_context_injection_count\": 0, \"medium_severity_error_count\": 0, \"course_question_submit_count\": 0, \"course_question_correct_count\": 0, \"training_question_submit_count\": 0, \"training_question_correct_count\": 0, \"generated_question_attempt_count\": 0, \"generated_question_attempt_correct_count\": 0}, \"strengths\": [\"暂无明显优势，建议继续积累学习证据\"], \"weaknesses\": [\"知识掌握\", \"排障能力\", \"自主探索能力\", \"学习投入度\"], \"score_model\": {\"rationale\": {\"autonomy_score\": \"强调独立探索与主动尝试，是过程能力核心维度之一。\", \"engagement_score\": \"衡量持续投入与练习稳定性，避免只看一次性结果。\", \"troubleshooting_score\": \"安全实验高度依赖排错与恢复，因此单列 20%。\", \"ai_collaboration_score\": \"衡量是否合理借助 AI，而非把 AI 当答案生成器。\", \"knowledge_mastery_score\": \"结果性学习证据，权重最高，用于衡量知识理解、实验达成和迁移掌握。\"}, \"overall_weights\": {\"autonomy_score\": 0.2, \"engagement_score\": 0.15, \"troubleshooting_score\": 0.2, \"ai_collaboration_score\": 0.15, \"knowledge_mastery_score\": 0.3}, \"dimension_breakdown\": {\"autonomy_score\": {\"label\": \"自主探索\", \"weight\": 0.2, \"components\": [{\"key\": \"path_diversity\", \"label\": \"有效探索路径多样性\", \"weight\": 0.4}, {\"key\": \"effective_operations\", \"label\": \"有效操作行为\", \"weight\": 0.3}, {\"key\": \"independent_attempt\", \"label\": \"独立尝试程度\", \"weight\": 0.3}]}, \"engagement_score\": {\"label\": \"学习投入\", \"weight\": 0.15, \"components\": [{\"key\": \"active_days\", \"label\": \"活跃天数\", \"weight\": 0.3}, {\"key\": \"lab_participation\", \"label\": \"实验参与与完成\", \"weight\": 0.35}, {\"key\": \"sustained_practice\", \"label\": \"持续练习行为\", \"weight\": 0.35}]}, \"troubleshooting_score\": {\"label\": \"排障能力\", \"weight\": 0.2, \"components\": [{\"key\": \"step_completion\", \"label\": \"当前步骤完成度\", \"weight\": 0.3}, {\"key\": \"recovery_after_error\", \"label\": \"引导后恢复能力\", \"weight\": 0.45}, {\"key\": \"verification_after_fix\", \"label\": \"修复验证能力\", \"weight\": 0.25}]}, \"ai_collaboration_score\": {\"label\": \"AI协同\", \"weight\": 0.15, \"components\": [{\"key\": \"contextual_help_quality\", \"label\": \"上下文化求助质量\", \"weight\": 0.35}, {\"key\": \"post_ai_action_conversion\", \"label\": \"AI 交互后行动转化\", \"weight\": 0.4}, {\"key\": \"ai_usage_moderation\", \"label\": \"适度使用与依赖控制\", \"weight\": 0.25}]}, \"knowledge_mastery_score\": {\"label\": \"知识掌握\", \"weight\": 0.3, \"components\": [{\"key\": \"course_question_accuracy\", \"label\": \"课程先导题正确率\", \"weight\": 0.35}, {\"key\": \"lab_task_mastery\", \"label\": \"实验 Flag / 关键任务达成\", \"weight\": 0.4}, {\"key\": \"training_question_accuracy\", \"label\": \"动态题库掌握度\", \"weight\": 0.25}]}}}, \"data_provenance\": {\"mode\": \"mixed_or_insufficient_data\", \"sourceTypes\": [], \"sourceCounts\": {}, \"excludedReasons\": [], \"calculationVersion\": \"capability-growth-v1\", \"eligibleRecordCount\": 0, \"excludedRecordCount\": 0, \"unverifiableRecordCount\": 0}, \"recommendations\": [{\"id\": \"knowledge_mastery-1\", \"tags\": [\"知识掌握\", \"画像推荐\", \"MODULE\", \"高优先级\"], \"type\": \"MODULE\", \"labId\": null, \"score\": 0.0, \"title\": \"SQL 注入基础实验\", \"action\": \"开始训练\", \"reason\": \"知识掌握当前得分 0.00，知识掌握度偏低，优先回补基础理论和题目复习模块。 已匹配真实模块「SQL 注入基础实验」。\", \"source\": \"student_profile_snapshot\", \"courseId\": null, \"moduleId\": 1, \"priority\": \"high\", \"dimension\": \"knowledge_mastery\", \"threshold\": 60, \"actionText\": \"开始训练\", \"difficulty\": 3, \"questionId\": null, \"knowledgeTags\": [\"[\\\"SQL注入\\\",\\\"Web安全\\\"]\", \"知识掌握\", \"SQL注入\", \"Web安全\"], \"dimension_name\": \"知识掌握\"}, {\"id\": \"troubleshooting-1\", \"tags\": [\"排障能力\", \"画像推荐\", \"MODULE\", \"高优先级\"], \"type\": \"MODULE\", \"labId\": null, \"score\": 0.0, \"title\": \"SQL 注入基础实验\", \"action\": \"开始训练\", \"reason\": \"排障能力当前得分 0.00，排障能力偏低，建议围绕排查、修复与实战复盘类资源补强。 已匹配真实模块「SQL 注入基础实验」。\", \"source\": \"student_profile_snapshot\", \"courseId\": null, \"moduleId\": 1, \"priority\": \"high\", \"dimension\": \"troubleshooting\", \"threshold\": 60, \"actionText\": \"开始训练\", \"difficulty\": 3, \"questionId\": null, \"knowledgeTags\": [\"[\\\"SQL注入\\\",\\\"Web安全\\\"]\", \"排障能力\", \"SQL注入\", \"Web安全\"], \"dimension_name\": \"排障能力\"}, {\"id\": \"autonomy-2\", \"tags\": [\"自主探索能力\", \"画像推荐\", \"MODULE\", \"高优先级\"], \"type\": \"MODULE\", \"labId\": null, \"score\": 0.0, \"title\": \"XSS 与 CSRF 基础实验\", \"action\": \"开始训练\", \"reason\": \"自主探索能力当前得分 0.00，自主探索能力偏低，建议先完成基础到中等难度的独立实操实验。 已匹配真实模块「XSS 与 CSRF 基础实验」。\", \"source\": \"student_profile_snapshot\", \"courseId\": null, \"moduleId\": 2, \"priority\": \"high\", \"dimension\": \"autonomy\", \"threshold\": 60, \"actionText\": \"开始训练\", \"difficulty\": 2, \"questionId\": null, \"knowledgeTags\": [\"[\\\"XSS\\\",\\\"CSRF\\\",\\\"Web安全\\\"]\", \"自主探索能力\", \"XSS\", \"Web安全\"], \"dimension_name\": \"自主探索能力\"}, {\"id\": \"engagement-2\", \"tags\": [\"学习投入度\", \"画像推荐\", \"MODULE\", \"高优先级\"], \"type\": \"MODULE\", \"labId\": null, \"score\": 0.0, \"title\": \"XSS 与 CSRF 基础实验\", \"action\": \"开始训练\", \"reason\": \"学习投入度当前得分 0.00，学习投入度偏低，建议先完成低难度、短周期、容易完成的模块。 已匹配真实模块「XSS 与 CSRF 基础实验」。\", \"source\": \"student_profile_snapshot\", \"courseId\": null, \"moduleId\": 2, \"priority\": \"high\", \"dimension\": \"engagement\", \"threshold\": 60, \"actionText\": \"开始训练\", \"difficulty\": 2, \"questionId\": null, \"knowledgeTags\": [\"[\\\"XSS\\\",\\\"CSRF\\\",\\\"Web安全\\\"]\", \"学习投入度\", \"XSS\", \"Web安全\"], \"dimension_name\": \"学习投入度\"}], \"source_strategy\": \"当前没有稳定知识标签表，知识掌握按 module_id/task_id 粒度的题目、Flag、实验完成证据替代。\", \"dimension_explanations\": {\"overall_score\": {\"weights\": {\"autonomy_score\": 0.2, \"engagement_score\": 0.15, \"troubleshooting_score\": 0.2, \"ai_collaboration_score\": 0.15, \"knowledge_mastery_score\": 0.3}, \"explanation\": \"一级维度采用结果与过程并重的固定权重：知识掌握 30%，排障能力 20%，自主探索 20%，AI 协同 15%，学习投入 15%。\", \"dimension_breakdown\": {\"autonomy_score\": {\"label\": \"自主探索\", \"weight\": 0.2, \"components\": [{\"key\": \"path_diversity\", \"label\": \"有效探索路径多样性\", \"weight\": 0.4}, {\"key\": \"effective_operations\", \"label\": \"有效操作行为\", \"weight\": 0.3}, {\"key\": \"independent_attempt\", \"label\": \"独立尝试程度\", \"weight\": 0.3}]}, \"engagement_score\": {\"label\": \"学习投入\", \"weight\": 0.15, \"components\": [{\"key\": \"active_days\", \"label\": \"活跃天数\", \"weight\": 0.3}, {\"key\": \"lab_participation\", \"label\": \"实验参与与完成\", \"weight\": 0.35}, {\"key\": \"sustained_practice\", \"label\": \"持续练习行为\", \"weight\": 0.35}]}, \"troubleshooting_score\": {\"label\": \"排障能力\", \"weight\": 0.2, \"components\": [{\"key\": \"step_completion\", \"label\": \"当前步骤完成度\", \"weight\": 0.3}, {\"key\": \"recovery_after_error\", \"label\": \"引导后恢复能力\", \"weight\": 0.45}, {\"key\": \"verification_after_fix\", \"label\": \"修复验证能力\", \"weight\": 0.25}]}, \"ai_collaboration_score\": {\"label\": \"AI协同\", \"weight\": 0.15, \"components\": [{\"key\": \"contextual_help_quality\", \"label\": \"上下文化求助质量\", \"weight\": 0.35}, {\"key\": \"post_ai_action_conversion\", \"label\": \"AI 交互后行动转化\", \"weight\": 0.4}, {\"key\": \"ai_usage_moderation\", \"label\": \"适度使用与依赖控制\", \"weight\": 0.25}]}, \"knowledge_mastery_score\": {\"label\": \"知识掌握\", \"weight\": 0.3, \"components\": [{\"key\": \"course_question_accuracy\", \"label\": \"课程先导题正确率\", \"weight\": 0.35}, {\"key\": \"lab_task_mastery\", \"label\": \"实验 Flag / 关键任务达成\", \"weight\": 0.4}, {\"key\": \"training_question_accuracy\", \"label\": \"动态题库掌握度\", \"weight\": 0.25}]}}}, \"autonomy_score\": {\"stats\": {\"command_count\": 0, \"operation_count\": 0, \"component_scores\": {\"path_diversity\": 0, \"independent_attempt\": 0, \"effective_operations\": 0}, \"file_change_count\": 0, \"independence_ratio\": 0.0, \"path_diversity_ratio\": 0.0, \"unique_command_count\": 0, \"ai_user_message_count\": 0}, \"weights\": [{\"key\": \"path_diversity\", \"label\": \"有效探索路径多样性\", \"weight\": 0.4}, {\"key\": \"effective_operations\", \"label\": \"有效操作行为\", \"weight\": 0.3}, {\"key\": \"independent_attempt\", \"label\": \"独立尝试程度\", \"weight\": 0.3}], \"explanation\": \"自主探索占综合分 20%。内部采用探索路径多样性 40%、有效操作行为 30%、独立尝试程度 30%，避免只看命令次数。\"}, \"engagement_score\": {\"stats\": {\"active_day_count\": 0, \"component_scores\": {\"active_days\": 0, \"lab_participation\": 0, \"sustained_practice\": 0}, \"lab_session_count\": 0, \"completed_lab_count\": 0, \"active_behavior_count\": 0}, \"weights\": [{\"key\": \"active_days\", \"label\": \"活跃天数\", \"weight\": 0.3}, {\"key\": \"lab_participation\", \"label\": \"实验参与与完成\", \"weight\": 0.35}, {\"key\": \"sustained_practice\", \"label\": \"持续练习行为\", \"weight\": 0.35}], \"explanation\": \"学习投入占综合分 15%。当前先用活跃天数 30%、实验参与与完成 35%、持续练习行为 35% 作为可落地代理指标。\"}, \"troubleshooting_score\": {\"stats\": {\"error_count\": 0, \"component_scores\": {\"step_completion\": 0, \"recovery_after_error\": 0.0, \"verification_after_fix\": 0}, \"low_severity_error_count\": 0, \"high_severity_error_count\": 0, \"medium_severity_error_count\": 0}, \"weights\": [{\"key\": \"step_completion\", \"label\": \"当前步骤完成度\", \"weight\": 0.3}, {\"key\": \"recovery_after_error\", \"label\": \"引导后恢复能力\", \"weight\": 0.45}, {\"key\": \"verification_after_fix\", \"label\": \"修复验证能力\", \"weight\": 0.25}], \"explanation\": \"排障能力强调卡住后的恢复过程，占综合分 20%。内部采用步骤完成度 30%、引导后恢复能力 45%、修复验证能力 25%。\"}, \"ai_collaboration_score\": {\"stats\": {\"component_scores\": {\"ai_usage_moderation\": 60.0, \"contextual_help_quality\": 60.0, \"post_ai_action_conversion\": 60.0}, \"ai_user_message_count\": 0, \"followup_activity_count\": 0, \"ai_context_message_count\": 0, \"ai_context_injection_count\": 0}, \"weights\": [{\"key\": \"contextual_help_quality\", \"label\": \"上下文化求助质量\", \"weight\": 0.35}, {\"key\": \"post_ai_action_conversion\", \"label\": \"AI 交互后行动转化\", \"weight\": 0.4}, {\"key\": \"ai_usage_moderation\", \"label\": \"适度使用与依赖控制\", \"weight\": 0.25}], \"explanation\": \"AI 协同占综合分 15%。它与自主探索不是对立维度：不使用 AI 记中性分，过度依赖才扣分；真正加分点在于上下文化求助和求助后的行动转化。\"}, \"knowledge_mastery_score\": {\"stats\": {\"component_scores\": {\"lab_task_mastery\": 0, \"course_question_accuracy\": 0, \"training_question_accuracy\": 0}, \"flag_correct_rate\": 0.0, \"lab_completion_rate\": 0.0, \"question_correct_rate\": 0.0, \"course_question_correct_rate\": 0.0, \"training_question_correct_rate\": 0.0}, \"weights\": [{\"key\": \"course_question_accuracy\", \"label\": \"课程先导题正确率\", \"weight\": 0.35}, {\"key\": \"lab_task_mastery\", \"label\": \"实验 Flag / 关键任务达成\", \"weight\": 0.4}, {\"key\": \"training_question_accuracy\", \"label\": \"动态题库掌握度\", \"weight\": 0.25}], \"explanation\": \"知识掌握强调结果性证据，占综合分 30%。内部采用课程先导题 35%、实验 Flag/关键任务 40%、动态题库 25%，兼顾基础理解、实操达成和迁移掌握。\"}}}',NULL,NULL,'2026-11-18 20:53:23.891633');
/*!40000 ALTER TABLE `student_profile_snapshot` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `task_knowledge_point`
--

DROP TABLE IF EXISTS `task_knowledge_point`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `task_knowledge_point` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `module_id` bigint DEFAULT NULL,
  `task_id` bigint NOT NULL,
  `knowledge_point_id` bigint NOT NULL,
  `relevance_weight` decimal(5,2) NOT NULL DEFAULT '1.00',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task_knowledge_point` (`module_id`,`task_id`,`knowledge_point_id`),
  KEY `idx_task_kp_task` (`task_id`),
  KEY `idx_task_kp_module_task` (`module_id`,`task_id`),
  KEY `idx_task_kp_kp` (`knowledge_point_id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `task_knowledge_point`
--

LOCK TABLES `task_knowledge_point` WRITE;
/*!40000 ALTER TABLE `task_knowledge_point` DISABLE KEYS */;
INSERT INTO `task_knowledge_point` VALUES (1,1,1,101,1.00,'2026-11-18 20:03:23.071702'),(2,1,2,102,1.00,'2026-11-18 20:03:23.071702'),(3,2,1,201,1.00,'2026-11-18 20:03:23.071702'),(4,3,1,301,1.00,'2026-11-18 20:03:23.071702'),(5,4,1,401,1.00,'2026-11-18 20:03:23.071702'),(6,4,2,402,1.00,'2026-11-18 20:03:23.071702'),(7,5,1,501,1.00,'2026-11-18 20:03:23.071702'),(8,6,1,601,1.00,'2026-11-18 20:03:23.071702');
/*!40000 ALTER TABLE `task_knowledge_point` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `teacher_class_analysis`
--

DROP TABLE IF EXISTS `teacher_class_analysis`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teacher_class_analysis` (
  `teaching_class_id` bigint NOT NULL,
  `requested_by` bigint DEFAULT NULL,
  `analysis_status` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'IDLE',
  `data_cutoff_at` datetime(6) DEFAULT NULL,
  `analysis_json` json DEFAULT NULL,
  `source_stats_json` json DEFAULT NULL,
  `last_attempt_at` datetime(6) DEFAULT NULL,
  `last_error_message` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `generated_at` datetime(6) DEFAULT NULL,
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`teaching_class_id`),
  KEY `idx_teacher_analysis_status` (`analysis_status`,`updated_at`),
  CONSTRAINT `chk_teacher_analysis_status` CHECK ((`analysis_status` in (_utf8mb4'IDLE',_utf8mb4'RUNNING',_utf8mb4'READY')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `teacher_class_analysis`
--

LOCK TABLES `teacher_class_analysis` WRITE;
/*!40000 ALTER TABLE `teacher_class_analysis` DISABLE KEYS */;
/*!40000 ALTER TABLE `teacher_class_analysis` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `teacher_course_analysis`
--

DROP TABLE IF EXISTS `teacher_course_analysis`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teacher_course_analysis` (
  `teacher_id` bigint NOT NULL,
  `teaching_class_id` bigint NOT NULL,
  `course_id` int NOT NULL,
  `analysis_scope` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL,
  `student_id` bigint NOT NULL DEFAULT '0',
  `analysis_status` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'IDLE',
  `analysis_json` longtext COLLATE utf8mb4_unicode_ci,
  `source_stats_json` longtext COLLATE utf8mb4_unicode_ci,
  `data_cutoff_at` datetime(6) DEFAULT NULL,
  `last_attempt_at` datetime(6) DEFAULT NULL,
  `last_error_message` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `generated_at` datetime(6) DEFAULT NULL,
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`teacher_id`,`teaching_class_id`,`course_id`,`analysis_scope`,`student_id`),
  KEY `idx_teacher_course_analysis_lookup` (`teaching_class_id`,`course_id`,`analysis_scope`,`student_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `teacher_course_analysis`
--

LOCK TABLES `teacher_course_analysis` WRITE;
/*!40000 ALTER TABLE `teacher_course_analysis` DISABLE KEYS */;
/*!40000 ALTER TABLE `teacher_course_analysis` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `teacher_intervention`
--

DROP TABLE IF EXISTS `teacher_intervention`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teacher_intervention` (
  `intervention_id` bigint NOT NULL AUTO_INCREMENT,
  `teacher_id` bigint NOT NULL,
  `teaching_class_id` bigint NOT NULL,
  `course_id` int DEFAULT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `action_type` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `knowledge_point_id` bigint DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `status` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ACTIVE',
  `baseline_at` datetime(6) NOT NULL,
  `due_at` datetime(6) NOT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`intervention_id`),
  KEY `idx_intervention_class_status_due` (`teaching_class_id`,`status`,`due_at`),
  KEY `idx_intervention_teacher_time` (`teacher_id`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `teacher_intervention`
--

LOCK TABLES `teacher_intervention` WRITE;
/*!40000 ALTER TABLE `teacher_intervention` DISABLE KEYS */;
/*!40000 ALTER TABLE `teacher_intervention` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `teacher_intervention_exercise_snapshot`
--

DROP TABLE IF EXISTS `teacher_intervention_exercise_snapshot`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teacher_intervention_exercise_snapshot` (
  `snapshot_id` bigint NOT NULL AUTO_INCREMENT,
  `intervention_id` bigint NOT NULL,
  `source_exercise_id` bigint NOT NULL,
  `source_version` int NOT NULL,
  `snapshot_json` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`snapshot_id`),
  UNIQUE KEY `uk_intervention_exercise_snapshot` (`intervention_id`,`source_exercise_id`),
  CONSTRAINT `fk_intervention_exercise_snapshot_parent` FOREIGN KEY (`intervention_id`) REFERENCES `teacher_intervention` (`intervention_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `teacher_intervention_exercise_snapshot`
--

LOCK TABLES `teacher_intervention_exercise_snapshot` WRITE;
/*!40000 ALTER TABLE `teacher_intervention_exercise_snapshot` DISABLE KEYS */;
/*!40000 ALTER TABLE `teacher_intervention_exercise_snapshot` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `teacher_intervention_question`
--

DROP TABLE IF EXISTS `teacher_intervention_question`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teacher_intervention_question` (
  `intervention_id` bigint NOT NULL,
  `generated_question_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `usage_type` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`intervention_id`,`generated_question_id`,`usage_type`),
  KEY `idx_intervention_question` (`generated_question_id`,`created_at`),
  CONSTRAINT `fk_intervention_question_parent` FOREIGN KEY (`intervention_id`) REFERENCES `teacher_intervention` (`intervention_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `teacher_intervention_question`
--

LOCK TABLES `teacher_intervention_question` WRITE;
/*!40000 ALTER TABLE `teacher_intervention_question` DISABLE KEYS */;
/*!40000 ALTER TABLE `teacher_intervention_question` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `teacher_intervention_student`
--

DROP TABLE IF EXISTS `teacher_intervention_student`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teacher_intervention_student` (
  `intervention_id` bigint NOT NULL,
  `student_id` bigint NOT NULL,
  `baseline_snapshot_json` json DEFAULT NULL,
  `latest_snapshot_json` json DEFAULT NULL,
  `assignment_status` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `training_session_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `started_at` datetime(6) DEFAULT NULL,
  `completed_at` datetime(6) DEFAULT NULL,
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`intervention_id`,`student_id`),
  KEY `idx_intervention_student_status` (`student_id`,`assignment_status`,`updated_at`),
  KEY `idx_intervention_training_session` (`training_session_id`),
  CONSTRAINT `fk_intervention_student_parent` FOREIGN KEY (`intervention_id`) REFERENCES `teacher_intervention` (`intervention_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `teacher_intervention_student`
--

LOCK TABLES `teacher_intervention_student` WRITE;
/*!40000 ALTER TABLE `teacher_intervention_student` DISABLE KEYS */;
/*!40000 ALTER TABLE `teacher_intervention_student` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `teacher_knowledge_analysis`
--

DROP TABLE IF EXISTS `teacher_knowledge_analysis`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teacher_knowledge_analysis` (
  `analysis_id` bigint NOT NULL AUTO_INCREMENT,
  `teacher_id` bigint NOT NULL,
  `teaching_class_id` bigint NOT NULL,
  `course_id` int NOT NULL,
  `knowledge_point_id` bigint NOT NULL,
  `analysis_status` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'IDLE',
  `analysis_json` longtext COLLATE utf8mb4_unicode_ci,
  `evidence_json` longtext COLLATE utf8mb4_unicode_ci,
  `last_attempt_at` datetime(6) DEFAULT NULL,
  `last_error_message` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `generated_at` datetime(6) DEFAULT NULL,
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`analysis_id`),
  UNIQUE KEY `uk_teacher_knowledge_scope` (`teacher_id`,`teaching_class_id`,`course_id`,`knowledge_point_id`),
  KEY `idx_teacher_knowledge_lookup` (`teaching_class_id`,`course_id`,`knowledge_point_id`,`analysis_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `teacher_knowledge_analysis`
--

LOCK TABLES `teacher_knowledge_analysis` WRITE;
/*!40000 ALTER TABLE `teacher_knowledge_analysis` DISABLE KEYS */;
/*!40000 ALTER TABLE `teacher_knowledge_analysis` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `teacher_knowledge_exercise`
--

DROP TABLE IF EXISTS `teacher_knowledge_exercise`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teacher_knowledge_exercise` (
  `exercise_id` bigint NOT NULL AUTO_INCREMENT,
  `analysis_id` bigint NOT NULL,
  `exercise_role` varchar(24) COLLATE utf8mb4_unicode_ci NOT NULL,
  `question_type` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `stem` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `options_json` longtext COLLATE utf8mb4_unicode_ci,
  `standard_answer` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `explanation` longtext COLLATE utf8mb4_unicode_ci,
  `difficulty` int NOT NULL DEFAULT '1',
  `generation_rationale` text COLLATE utf8mb4_unicode_ci,
  `review_status` varchar(24) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING_REVIEW',
  `review_comment` text COLLATE utf8mb4_unicode_ci,
  `source_version` int NOT NULL DEFAULT '1',
  `reviewed_by` bigint DEFAULT NULL,
  `reviewed_at` datetime(6) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`exercise_id`),
  UNIQUE KEY `uk_teacher_knowledge_exercise_role` (`analysis_id`,`exercise_role`),
  KEY `idx_teacher_knowledge_exercise_review` (`review_status`,`updated_at`),
  CONSTRAINT `fk_teacher_knowledge_exercise_analysis` FOREIGN KEY (`analysis_id`) REFERENCES `teacher_knowledge_analysis` (`analysis_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `teacher_knowledge_exercise`
--

LOCK TABLES `teacher_knowledge_exercise` WRITE;
/*!40000 ALTER TABLE `teacher_knowledge_exercise` DISABLE KEYS */;
/*!40000 ALTER TABLE `teacher_knowledge_exercise` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `teacher_student_analysis`
--

DROP TABLE IF EXISTS `teacher_student_analysis`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teacher_student_analysis` (
  `teacher_id` bigint NOT NULL,
  `teaching_class_id` bigint NOT NULL,
  `student_id` bigint NOT NULL,
  `analysis_status` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'IDLE',
  `data_cutoff_at` datetime(6) DEFAULT NULL,
  `analysis_json` json DEFAULT NULL,
  `source_stats_json` json DEFAULT NULL,
  `last_attempt_at` datetime(6) DEFAULT NULL,
  `last_error_message` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `generated_at` datetime(6) DEFAULT NULL,
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`teacher_id`,`teaching_class_id`,`student_id`),
  KEY `idx_student_analysis_class_status` (`teaching_class_id`,`analysis_status`,`updated_at`),
  KEY `idx_student_analysis_student` (`student_id`,`updated_at`),
  CONSTRAINT `chk_teacher_student_analysis_status` CHECK ((`analysis_status` in (_utf8mb4'IDLE',_utf8mb4'RUNNING',_utf8mb4'READY')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `teacher_student_analysis`
--

LOCK TABLES `teacher_student_analysis` WRITE;
/*!40000 ALTER TABLE `teacher_student_analysis` DISABLE KEYS */;
/*!40000 ALTER TABLE `teacher_student_analysis` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `teacher_typical_question`
--

DROP TABLE IF EXISTS `teacher_typical_question`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teacher_typical_question` (
  `teacher_id` bigint NOT NULL,
  `generated_question_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`teacher_id`,`generated_question_id`),
  UNIQUE KEY `uk_teacher_typical_question` (`teacher_id`,`generated_question_id`),
  KEY `idx_typical_question_question` (`generated_question_id`,`created_at`),
  CONSTRAINT `fk_typical_question_generated` FOREIGN KEY (`generated_question_id`) REFERENCES `generated_question` (`generated_question_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `teacher_typical_question`
--

LOCK TABLES `teacher_typical_question` WRITE;
/*!40000 ALTER TABLE `teacher_typical_question` DISABLE KEYS */;
/*!40000 ALTER TABLE `teacher_typical_question` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `training_session`
--

DROP TABLE IF EXISTS `training_session`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `training_session` (
  `training_session_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` bigint NOT NULL,
  `class_id` bigint DEFAULT NULL,
  `course_id` bigint DEFAULT NULL,
  `profile_snapshot_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `source_type` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'personalized_training',
  `diagnose_result_json` json NOT NULL,
  `training_context_json` json DEFAULT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`training_session_id`),
  KEY `idx_training_session_user_time` (`user_id`,`created_at`),
  KEY `idx_training_session_course_time` (`course_id`,`created_at`),
  KEY `idx_training_session_profile` (`profile_snapshot_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `training_session`
--

LOCK TABLES `training_session` WRITE;
/*!40000 ALTER TABLE `training_session` DISABLE KEYS */;
/*!40000 ALTER TABLE `training_session` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-11-23 18:27:24
