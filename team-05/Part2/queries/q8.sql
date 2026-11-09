SELECT m.member_id, m.email
FROM member m
JOIN checkout ch ON ch.member_id = m.member_id
JOIN tool t ON t.tool_id = ch.tool_id
JOIN category c ON c.category_id = t.category_id
WHERE c.requires_certification = TRUE
GROUP BY m.member_id, m.email
HAVING COUNT(DISTINCT c.category_id) = (
    SELECT COUNT(*) FROM category WHERE requires_certification = TRUE
)
ORDER BY m.member_id ASC;