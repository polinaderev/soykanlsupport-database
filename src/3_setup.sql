create database frnlsupport CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

use frnlsupport;

set global time_zone = '+1:00';

create table Places (
	place_id int unsigned not null auto_increment,
	postcode varchar(6) not null unique,
	coordinates varchar(255) not null,
	place_name varchar(100) not null,
	primary key(place_id)
);

create table People (
	telegram_id bigint unsigned not null,
	first_name varchar(100),
	last_name varchar(100),
	is_banned bool default 0,
	is_approved_volunteer bool default 0,
	prefers_whole_nl bool default 0,
	place_id int unsigned,
	primary key (telegram_id),
	foreign key(place_id) references Places(place_id)
);

create table Usernames (
	 username_id int unsigned not null auto_increment,
	 username varchar(255) not null unique,
	 telegram_id bigint unsigned not null,
	 primary key(username_id),
	 foreign key(telegram_id) references People(telegram_id)
);

create table Feedback (
	feedback_id int unsigned not null auto_increment,
	timestamp_created timestamp default current_timestamp,
	description text not null,
	description_translation text default null,
	permission_to_publish bool not null,
	status enum('new', 'posted', 'messaged_to_addressee', 'responded_to_author', 'rejected') default 'new',
	telegram_id bigint unsigned not null,
	primary key(feedback_id),
	foreign key(telegram_id) references People(telegram_id)
);

create table Files (
	file_id int unsigned not null auto_increment,
	`path` varchar(511) not null,
	`size_kb` bigint unsigned not null,
	feedback_id int unsigned not null,
	primary key(file_id),
	foreign key(feedback_id) references Feedback(feedback_id)
);

create table Requests(
	request_id int unsigned not null auto_increment,
	old_request_id varchar(10),
	created timestamp default current_timestamp,
	description text not null,
	description_translation text default null,
	items_list_original text,
	priority enum('1', '2', '3') default null,
	status enum('new', 'ready', 'posted', 'scheduled', 'matched', 'partially matched', 'completed',
				'partially completed', 'rejected', 'archived', 'auto_matched_partially', 'auto_matched_full',
				'auto_complete', 'pending', 'fixed_auto_complete', 'auto_invalid') default 'new',
	last_status_change timestamp default current_timestamp,
	admin_comment text default null,
	requester_id bigint unsigned not null,
	primary key(request_id),
	foreign key(requester_id) references People(telegram_id)
);

create table Items(
	item_id int unsigned not null auto_increment,
	short_description_en varchar(255) not null,
	short_description_ru varchar(255) not null,
	short_description_ua varchar(255) not null,
	description_en varchar(1023) not null,
	description_ru varchar(1023) not null,
	description_ua varchar(1023) not null,
	`size` varchar(31) default null,
	`type` enum('ELECTRONICS', 'LUGGAGE', 'BIKE', 'APPLIANCES', 'CLOTHES', 'OTHER', 'FOOD', 'MEDICINE', 'TRANSFER', 
				'KIDS', 'PETS', 'HOBBY', 'HOUSEHOLD', 'HYGIENE', 'ADMIN'),
	primary key(item_id)
);

create table Subrequests(
	subrequest_id int unsigned not null auto_increment,
	created timestamp default current_timestamp,
	priority enum('1', '2', '3', '') default null,
	status enum('new', 'ready', 'posted', 'scheduled', 'matched', 'completed', 'rejected', 'archived', 
				'auto_matched_full', 'auto_complete', 'pending', 'fixed_auto_complete', 'auto_invalid')
				default 'new',
	post_link varchar(255) default null,
	last_status_change timestamp default current_timestamp,
	fulfil_src enum('map', 'bot', 'channel', 'admin') default null,
	request_id int unsigned not null,
	item_id int unsigned not null,
	volunteer_id bigint unsigned not null,
	primary key(subrequest_id),
	foreign key(request_id) references Requests(request_id),
	foreign key(item_id) references Items(item_id),
	foreign key(volunteer_id) references People(telegram_id)
);

-- mapping tables for the many-to-many relationships

create table Volunteers_Items_preference(
	volunteer_id bigint unsigned not null,
	item_id int unsigned not null,
	foreign key(volunteer_id) references People(telegram_id),
	foreign key(item_id) references Items(item_id)
);