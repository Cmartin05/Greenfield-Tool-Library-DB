SELECT m.member_id, m.first_name, m.last_name, SUM(ch.late_fee) AS total_fees
FROM member m
JOIN checkout ch USING (member_id)
GROUP BY m.member_id, m.first_name, m.last_name
HAVING SUM(ch.late_fee) > 75
ORDER BY total_fees DESC, m.member_id ASC;