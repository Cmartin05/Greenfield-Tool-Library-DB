# AI Usage Log

## Part 1 - Deliverable 1: Data Exploration

I asked ChatGPT to help examine the `members.csv` and `loans.csv` files to identify duplicate records, matching member information, and invalid return dates. It provided a Python script using CSV processing and date comparison techniques to demonstrate how the results could be calculated. It also helped explain the methods used for each calculation.

## Part 2 - Schema, Loading, and Queries

| Date | Tool | What I asked | What I did with the answer |
|---|---|---|---|
| 2026-11-08 | Deepseek | Asked it to compare my draft `schema.sql` against the reference schema and list any mismatches in column names, types, or constraints. | It identified the renames (`requires_cert` to `requires_certification`, `joined` to `join_date`, `purchased` to `purchase_date`, `price` to `purchase_price`, `condition` to `tool_condition`), the VARCHAR/DECIMAL width reductions, the missing `AUTO_INCREMENT` on `checkout.checkout_id`, and the missing `DEFAULT 0.00` on `checkout.late_fee`. I applied each edit myself and re-ran `schema.sql` against a fresh database to confirm it executes cleanly. |
| 2026-11-08 | DeepSeek | `load.sql` failed with `Data truncated for column 'status'` on members.csv and the same for `'condition'` on inventory.csv. Asked it to diagnose. | It explained that `LINES TERMINATED BY '\n'` leaves a trailing `\r` on the last column of CRLF-terminated files. I added six `UPDATE stg_* SET col = REPLACE(col, '\r', '')` statements after the `LOAD DATA` blocks. Reloaded from scratch and confirmed row counts (category 8, member 340, staff 11, tool 260, certification 369, checkout 4066) and that no `\r` remained in `staff.email`. |
| 2026-11-08 | DeepSeek | Asked it to help translate the eight query specs (required columns and sort order) into SQL. | It produced draft SQL for q1 to q8. I rewrote each in the style of the class examples (uppercase keywords, `JOIN ... USING`, explicit `ASC`/`DESC`, single-letter aliases) and tested each against the loaded database. |