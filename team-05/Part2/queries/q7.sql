WITH tool_counts AS (
    SELECT c.name AS category_name,
           t.tool_id,
           t.name AS tool_name,
           COUNT(*) AS checkout_count
    FROM category c
    JOIN tool t     ON t.category_id = c.category_id
    JOIN checkout ch ON ch.tool_id = t.tool_id
    GROUP BY c.name, t.tool_id, t.name
),
ranked AS (
    SELECT category_name, tool_id, tool_name, checkout_count,
           RANK() OVER (PARTITION BY category_name
                        ORDER BY checkout_count DESC) AS category_rank
    FROM tool_counts
)
SELECT category_name, tool_id, tool_name, checkout_count, category_rank
FROM ranked
WHERE category_rank <= 3
ORDER BY category_name ASC, category_rank ASC, tool_id ASC;