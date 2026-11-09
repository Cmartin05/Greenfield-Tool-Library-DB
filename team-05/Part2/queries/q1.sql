SELECT t.tool_id, t.name AS tool_name, c.name AS category_name
FROM tool t
JOIN category c USING (category_id)
WHERE t.tool_condition = 'needs_repair'
ORDER BY t.tool_id ASC;