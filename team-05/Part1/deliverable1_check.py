"""Verify the three Deliverable 1 counts from the unmodified CSV packet."""
import csv
import json
from collections import Counter
from datetime import datetime
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parent

def read_csv(filename):
    with (DATA_DIR / filename).open(newline='', encoding='utf-8-sig') as file:
        return list(csv.DictReader(file))

def normalize_email(email):
    return email.strip().lower()

def parse_date(value):
    value = value.strip()
    if not value:
        return None
    for pattern in ('%Y-%m-%d', '%m/%d/%Y'):
        try:
            return datetime.strptime(value, pattern).date()
        except ValueError:
            continue
    raise ValueError(f'Unknown date format: {value!r}')

loans = read_csv('loans.csv')
members = read_csv('members.csv')

focus_member_rows = sum(
    normalize_email(row['member_email']) == 'carlos.novak781@proton.me'
    for row in loans
)

email_counts = Counter(normalize_email(row['email']) for row in members)
duplicate_member_rows = sum(count - 1 for count in email_counts.values())

bad_return_rows = sum(
    (back_date := parse_date(row['back_date'])) is not None
    and back_date < parse_date(row['out_date'])
    for row in loans
)

results = {
    'focus_member_rows': focus_member_rows,
    'duplicate_member_rows': duplicate_member_rows,
    'bad_return_rows': bad_return_rows,
}

with (DATA_DIR / 'part1_answers.json').open('w', encoding='utf-8') as file:
    json.dump(results, file, indent=2)
    file.write('\n')

print(json.dumps(results, indent=2))