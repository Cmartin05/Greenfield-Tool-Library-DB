SELECT m.member_id, m.email
FROM member m
WHERE (SELECT COUNT(DISTINCT t.category_id)
       FROM checkout ch
       JOIN tool t USING (tool_id)
       WHERE ch.member_id = m.member_id
         AND t.category_id IN (SELECT category_id
                               FROM category
                               WHERE requires_certification = TRUE))
      = (SELECT COUNT(*) FROM category WHERE requires_certification = TRUE)
ORDER BY m.member_id ASC;