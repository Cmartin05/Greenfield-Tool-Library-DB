SELECT t.tool_id, t.name AS tool_name, COUNT(ch.checkout_id) AS times_checked_out
FROM tool t
LEFT JOIN checkout ch USING (tool_id)
GROUP BY t.tool_id, t.name
HAVING COUNT(ch.checkout_id) > (SELECT COUNT(*) FROM checkout) / (SELECT COUNT(*) FROM tool)
ORDER BY times_checked_out DESC, t.tool_id ASC;