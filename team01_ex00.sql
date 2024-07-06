WITH select_all_users
     AS (SELECT CASE
                  WHEN "user".NAME IS NULL THEN 'not defined'
                  ELSE "user".NAME
                END                AS NAME,
                CASE
                  WHEN "user".lastname IS NULL THEN 'not defined'
                  ELSE "user".lastname
                END                AS lastname,
                balance.type,
                Sum(balance.money) AS volume,
                CASE
                  WHEN currency.NAME IS NULL THEN 'not defined'
                  ELSE currency.NAME
                END                AS currency_name,
                CASE
                  WHEN currency.rate_to_usd IS NULL THEN 1
                  ELSE currency.rate_to_usd
                END                AS rate_to_usd,
                currency.updated
         FROM   "user"
                RIGHT JOIN balance
                        ON balance.user_id = "user".id
                LEFT JOIN currency
                       ON currency.id = balance.currency_id
         GROUP  BY "user".NAME,
                   lastname,
                   type,
                   currency_name,
                   rate_to_usd,
                   currency.updated),
     count_last_update
     AS (SELECT NAME,
                lastname,
                type,
                volume,
                currency_name,
                first_value(rate_to_usd)
                  OVER (
                    partition BY NAME, lastname, type, volume
                    ORDER BY updated DESC) AS last_rate_to_usd
         FROM   select_all_users)

         
SELECT NAME,
       lastname,
       type,
       volume,
       currency_name,
       last_rate_to_usd,
       volume * last_rate_to_usd AS total_volume_in_usd
FROM   count_last_update
GROUP  BY NAME,
          lastname,
          type,
          volume,
          currency_name,
          last_rate_to_usd
ORDER  BY NAME DESC,
          lastname,
          type;