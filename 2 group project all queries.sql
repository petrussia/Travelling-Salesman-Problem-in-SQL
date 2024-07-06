create table "user"
(id bigint primary key ,
 name varchar,
 lastname varchar);

insert into "user" values (1,'Иван', 'Иванов');
insert into "user" values (2,'Петр', null);
insert into "user" values (3, null, 'Сидоров');

create table currency(
    id bigint not null ,
    name varchar not null ,
    rate_to_usd numeric,
    updated timestamp
);

insert into currency values (100, 'EUR', 0.9, '2022-03-03 13:31');
insert into currency values (100, 'EUR', 0.89, '2022-03-02 12:31');
insert into currency values (100, 'EUR', 0.87, '2022-03-02 08:00');
insert into currency values (100, 'EUR', 0.9, '2022-03-01 15:36');
insert into currency values (200, 'USD', 1, '2022-03-03 13:31');
insert into currency values (200, 'USD', 1, '2022-03-02 12:31');
insert into currency values (300, 'JPY', 0.0087, '2022-03-03 13:31');
insert into currency values (300, 'JPY', 0.0079, '2022-03-01 13:31');

create table balance
(user_id bigint,
 money numeric,
 type integer,
 currency_id integer,
 updated timestamp);

insert into balance values (4, 120,1, 200, '2022-01-01 01:31');
insert into balance values (4, 120,0, 300, '2022-01-01 01:31');
insert into balance values (1, 20,1, 100, '2022-01-01 13:31');
insert into balance values (1, 200,1, 100, '2022-01-09 13:31');
insert into balance values (1, 190,1, 100, '2022-01-10 13:31');
insert into balance values (2, 100,2, 210, '2022-01-09 13:31');
insert into balance values (2, 103,2, 210, '2022-01-10 13:31');
insert into balance values (3, 50,0, 100, '2022-01-09 13:31');
insert into balance values (3, 500,1, 200, '2022-01-09 13:31');
insert into balance values (3, 500,2, 300, '2022-01-09 13:31');


select * from "user";
select * from currency;
select * from balance;

SELECT *
FROM Currency
WHERE name = 'EUR'
ORDER BY updated DESC;

SELECT *
FROM Balance
WHERE user_id = 103
ORDER BY type, updated DESC;


-- 0
with select_all_users as (
	select case 
			when "user".name is null then 'not defined'
			else "user".name end as name,
		   case
			when "user".lastname is null then 'not defined'
			else "user".lastname end as lastname, 
			balance.type, sum(balance.money) as volume, 
			case
			when currency.name is null then 'not defined'
			else currency.name end as currency_name,
		   case 
			when currency.rate_to_usd is null then 1
			else currency.rate_to_usd end as rate_to_usd,
			currency.updated
	from "user"
		right join balance on balance.user_id = "user".id
		left join currency on currency.id = balance.currency_id
	group by "user".name, lastname, type, currency_name, rate_to_usd, currency.updated
),
	count_last_update as (
	select name, lastname, type, volume, currency_name,
	first_value(rate_to_usd) over 
	(partition by name, lastname, type, volume order by updated desc) 
	as last_rate_to_usd
	from select_all_users
	)

	
select name, lastname, type, volume, currency_name, last_rate_to_usd, 
	volume * last_rate_to_usd as total_volume_in_usd
from count_last_update
group by name, lastname, type, volume, currency_name, last_rate_to_usd
order by name desc, lastname, type;


-- 1
insert into currency values (100, 'EUR', 0.85, '2022-01-01 13:29'); 
insert into currency values (100, 'EUR', 0.79, '2022-01-08 13:29');


-- select user_id, money, type, currency_id, balance.updated,
-- 	-- case
-- 		-- when max(c1.updated) is null then c2.rate_to_usd
-- 		-- when min(c2.updated) is null then c1.rate_to_usd
-- 		min(c2.updated) 
-- 	from balance 
-- 	join currency on currency.id = balance.currency_id
-- 		-- left join currency c1 on c1.updated < balance.updated
-- 		left join currency c2 on c2.updated > balance.updated and c2.id = balance.currency_id
-- 	group by user_id, money, type, currency_id, 
-- 	balance.updated, c2.rate_to_usd

-- with count_nearest_date as (
-- 	select user_id, money, type, currency_id, balance.updated,
-- 	case
-- 		-- when max(c1.updated) is null then c2.rate_to_usd
-- 		-- when min(c2.updated) is null then c1.rate_to_usd
-- 		when balance.updated - max(c1.updated) > 
-- 			 balance.updated - min(c2.updated) 
-- 		then c1.rate_to_usd
-- 		else c2.rate_to_usd end as rate_to_usd
-- 	from balance 
-- 	join currency on currency.id = balance.currency_id
-- 		left join currency c1 on c1.updated < balance.updated
-- 		left join currency c2 on c2.updated > balance.updated
-- 	group by user_id, money, type, currency_id, 
-- 	balance.updated, c1.rate_to_usd, c2.rate_to_usd
-- )
-- 	select * from count_nearest_date group by user_id, money, 
-- 	type, currency_id, updated, rate_to_usd
-- 	select_all_users as (
-- 	select case 
-- 			when "user".name is null then 'not defined'
-- 			else "user".name end as name,
-- 		   case
-- 			when "user".lastname is null then 'not defined'
-- 			else "user".lastname end as lastname, 
-- 			case
-- 			when currency.name is null then 'not defined'
-- 			else currency.name end as currency_name,
-- 		 	balance.money, balance.updated,
-- 			case
-- 			when max(c1.updated) is null then c2.rate_to_usd
-- 			when min(c2.updated) is null then c1.rate_to_usd
-- 			when balance.updated - max(c1.updated) > 
-- 				 balance.updated - min(c2.updated) 
-- 			then c1.rate_to_usd
-- 			else c2.rate_to_usd end as rate_to_usd 
-- 	from "user"
-- 		right join balance on balance.user_id = "user".id
-- 		join currency on currency.id = balance.currency_id
-- 		left join currency c1 on c1.updated < balance.updated
-- 		left join currency c2 on c2.updated > balance.updated
-- 	group by "user".name, lastname, currency_name, money, 
-- 	currency.rate_to_usd, balance.updated, c1.rate_to_usd, c2.rate_to_usd 
-- )
-- select * from select_all_users




WITH get_volume AS (SELECT ROW_NUMBER() OVER (ORDER BY name) AS id,
                           COALESCE(u.name, 'not defined') AS name,
                           COALESCE(u.lastname, 'not defined') AS lastname,
                           b.money AS volume,
                           b.currency_id AS currency_id,
                           b.updated AS updated
                    FROM balance b
                    LEFT JOIN "user" u
                           ON u.id = b.user_id),							 
	get_all_update AS (SELECT gv.*, c.name AS currency_name, c.updated AS currency_updated, 
                              c.rate_to_usd, gv.volume * c.rate_to_usd
                       FROM get_volume gv
	                   JOIN currency c
	                       ON c.id = gv.currency_id
	                   ORDER BY 1 DESC, 2 ASC, 3 ASC),
	get_rate AS (SELECT DISTINCT id, gau.currency_name,
	                             coalesce((SELECT rate_to_usd
	                                       FROM get_all_update gau1 
	                                       WHERE gau.id = gau1.id AND gau1.updated > gau1.currency_updated 
	                                       ORDER BY gau1.currency_updated DESC
	                                       LIMIT 1), 
	                                      (SELECT rate_to_usd
	                                       FROM get_all_update gau2 
	                                       WHERE gau.id = gau2.id  
	                                       ORDER BY gau2.currency_updated ASC
	                                       LIMIT 1)) AS rate_to_usd
	             FROM get_all_update gau)

SELECT name, lastname, currency_name, volume * rate_to_usd AS currency_in_usd
FROM get_volume gv
RIGHT JOIN get_rate gr
	ON gv.id = gr.id
ORDER BY 1 DESC, 2, 3, gv.updated DESC