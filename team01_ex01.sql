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