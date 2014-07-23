-- [auth]

CREATE TABLE sess (
id binary(20) primary key,
user_id int not null,
now datetime not null,
-- [login]
new_pass tinyint comment "0/1 - сессия создана для регистрации",
-- [auth]
INDEX(now), INDEX(user_id)
) ENGINE=memory;

-- [login]
CREATE TABLE `user` (
id int primary key AUTO_INCREMENT,
email varchar(100) not null,
pass varchar(100) not null,
is_admin tinyint not null default 0,
name varchar(255) not null,
INDEX(email, pass)
) ENGINE=INNODB;

/*CREATE TABLE provider (
) ENGINE=INNODB;*/

CREATE TABLE account (
id int primary key AUTO_INCREMENT,
user_id int not null,
url varchar(255) not null,
INDEX(user_id)
) ENGINE=INNODB;

INSERT INTO `user` (id, email, pass, is_admin, name) VALUES (1, '@', '123', 1, 'тестовый admin'), (2, 'u@', '123', 0, 'тестовый пользователь')
