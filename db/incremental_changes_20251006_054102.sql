INSERT INTO _posts_v_rels(id,"order",parent_id,path,posts_id,categories_id,users_id) VALUES(1,1,2,'version.authors',NULL,NULL,1);
INSERT INTO _posts_v_rels(id,"order",parent_id,path,posts_id,categories_id,users_id) VALUES(2,1,3,'version.authors',NULL,NULL,1);
INSERT INTO _posts_v_rels(id,"order",parent_id,path,posts_id,categories_id,users_id) VALUES(3,1,4,'version.authors',NULL,NULL,1);
INSERT INTO _posts_v_rels(id,"order",parent_id,path,posts_id,categories_id,users_id) VALUES(4,1,5,'version.authors',NULL,NULL,1);
INSERT INTO _posts_v_rels(id,"order",parent_id,path,posts_id,categories_id,users_id) VALUES(5,1,6,'version.authors',NULL,NULL,1);
INSERT INTO _posts_v_rels(id,"order",parent_id,path,posts_id,categories_id,users_id) VALUES(6,1,7,'version.authors',NULL,NULL,1);
UPDATE payload_migrations SET updated_at='2025-10-06 09:39:54' WHERE id=1;
UPDATE payload_preferences SET "key"='form-submissions-list', updated_at='2025-10-06T09:39:04.403Z', created_at='2025-10-06T09:39:04.404Z' WHERE id=7;
UPDATE payload_preferences SET "key"='search-list', updated_at='2025-10-06T09:39:05.468Z', created_at='2025-10-06T09:39:05.469Z' WHERE id=8;
DELETE FROM payload_preferences WHERE id=9;
UPDATE payload_preferences_rels SET parent_id=1 WHERE id=1;
UPDATE payload_preferences_rels SET parent_id=2 WHERE id=2;
DELETE FROM payload_preferences_rels WHERE id=3;
INSERT INTO payload_preferences_rels(id,"order",parent_id,path,users_id) VALUES(5,NULL,3,'user',1);
INSERT INTO payload_preferences_rels(id,"order",parent_id,path,users_id) VALUES(6,NULL,4,'user',1);
INSERT INTO payload_preferences_rels(id,"order",parent_id,path,users_id) VALUES(7,NULL,5,'user',1);
INSERT INTO payload_preferences_rels(id,"order",parent_id,path,users_id) VALUES(8,NULL,6,'user',1);
INSERT INTO payload_preferences_rels(id,"order",parent_id,path,users_id) VALUES(9,NULL,7,'user',1);
INSERT INTO payload_preferences_rels(id,"order",parent_id,path,users_id) VALUES(10,NULL,8,'user',1);
INSERT INTO posts_rels(id,"order",parent_id,path,posts_id,categories_id,users_id) VALUES(1,1,1,'authors',NULL,NULL,1);
DROP TABLE users; -- due to schema mismatch
CREATE TABLE `users` (
	`id` integer PRIMARY KEY NOT NULL,
	`name` text,
	`updated_at` text DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')) NOT NULL,
	`created_at` text DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')) NOT NULL,
	`email` text NOT NULL,
	`reset_password_token` text,
	`reset_password_expiration` text,
	`salt` text,
	`hash` text,
	`login_attempts` numeric DEFAULT 0,
	`lock_until` text
);
INSERT INTO users(id,name,updated_at,created_at,email,reset_password_token,reset_password_expiration,salt,hash,login_attempts,lock_until) VALUES(1,'Jese','2025-10-06T09:03:59.288Z','2025-10-04T10:25:24.975Z','manjou132@gmial.com',NULL,NULL,'885ec58dfe919ac9e6c233a5fa91e9a7e7a63b93137d6c1645929dedc8b6e53c','00d8c5980abe6a8a3c265736197fae5acbd3e07547664334bd686bc21d9e0582746a1d1c64ba7c8d52b0672b1e7c7460b87100edea468451b7876f6bc7b4ef898ffad21aae45514e9481442257e276335f91033bde72881063409b9af75b8eb7bfa2f2df47230f1a5c3b58cd6385414cb20fe4ef6b21aff3c550c31b711301c74c5855f9d84186a8f02e75069b5990a94fba08c88cd47d341602975751af482c2c5bc5695326ee79a2000287b171cddb2d30306af0da2c4ad3528513e23041cac0de6574fb9ab0778461f5931096d0bcfc9addc09ee28a9ba333fd2bc556efce813d40fc9b78f82f219af9f0f6cbfb239a1e3576c9643248f4ad8f7df137eb77bdf98b06b0c5a5dacd1aa9b3b153850e08962ebbbd28e8312765250d42ec91c5ac11d7689e48ae3fcf58b27674f3f5cbf7627d435ff17c53c3677665384c8c05645382e0d577aff5d2a5a83287628e48df3a5efafea805edc64652c7d39e60e0680de2a073a91c14efb02583e0abd2b6c698cfd2c5bc30b31eac95d21ab4b5736b58001d91e0c2b4963f848c7d160111404908308b17ba700d95fb0a4e5d9c541156ef70919ed6018e55d89188b1624ba24c6cd215aafc19ca6bd7d07a99cc5d5a27954b06b1e81ccf8e2a7fe62a8f8f1077519a29f6407968bad4c27ffaef91f96fe6130865d913198c96592d3eb7e802e88ee2c1e1119cb5435ff3eeab5e6e',2,NULL);
CREATE INDEX `users_updated_at_idx` ON `users` (`updated_at`);
CREATE INDEX `users_created_at_idx` ON `users` (`created_at`);
CREATE UNIQUE INDEX `users_email_idx` ON `users` (`email`);
