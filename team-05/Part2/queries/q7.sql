SELECT category_name, tool_id, tool_name, checkout_count, category_rank
FROM (
    SELECT c.name AS category_name, t.tool_id, t.name AS tool_name,
           COUNT(ch.checkout_id) AS checkout_count,
           RANK() OVER (PARTITION BY c.category_id
                        ORDER BY COUNT(ch.checkout_id) DESC) AS category_rank
    FROM category c
    JOIN tool t ON t.category_id = c.category_id
    JOIN checkout ch ON ch.tool_id = t.tool_id
    GROUP BY c.category_id, c.name, t.tool_id, t.name
) ranked
WHERE category_rank <= 3
ORDER BY category_name ASC, category_rank ASC, tool_id ASC;