SELECT m.member_id, m.email
FROM member m
LEFT JOIN checkout ch USING (member_id)
WHERE ch.checkout_id IS NULL
ORDER BY m.member_id ASC;