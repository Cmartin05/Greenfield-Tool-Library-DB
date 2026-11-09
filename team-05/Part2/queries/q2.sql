SELECT c.name AS category_name, COUNT(ch.checkout_id) AS checkout_count
FROM category c
LEFT JOIN tool t ON t.category_id = c.category_id
LEFT JOIN checkout ch ON ch.tool_id = t.tool_id
GROUP BY c.category_id, c.name
ORDER BY checkout_count DESC, category_name ASC;