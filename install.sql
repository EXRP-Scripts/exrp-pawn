CREATE TABLE IF NOT EXISTS `pawnshop_job_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job` text NOT NULL,
  `label` text NOT NULL,
  `items` text NOT NULL,
  `valuations` text DEFAULT '{}',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

CREATE TABLE IF NOT EXISTS `pawn_store_orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(64) NOT NULL,
  `job` varchar(64) NOT NULL,
  `items` longtext NOT NULL,
  `reward` int(11) NOT NULL,
  `location` varchar(64) NOT NULL,
  `completed` tinyint(1) DEFAULT 0,
  `created_at` int(11) NOT NULL,
  `dueby` int(11) NOT NULL,
  `completed_at` int(11) DEFAULT NULL,
  `created_by` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;


