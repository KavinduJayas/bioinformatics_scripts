#!/usr/bin/env python3
import re, csv, sys
from pathlib import Path

log_path = Path('err.log')
out_path = Path('timings.csv')

pat = re.compile(r"\[M::([^\]:]+)::([0-9.]+)(?:\*([0-9.]+))?(?:@([0-9.]+)GB)?\]")

if not log_path.exists():
    print('err.log not found', file=sys.stderr)
    sys.exit(1)

entries = []
with log_path.open() as f:
    for line in f:
        m = pat.search(line)
        if m:
            func, ts, cores, mem = m.groups()
            if func == 'pec':
                continue
            ts = float(ts)
            cores = float(cores) if cores else None
            entries.append({'func': func, 'ts': ts, 'cores': cores})

# compute intervals preserving log order (no categorization)
rows = []
prev = None
for e in entries:
    # entries are already in log order; no sorting
    if e['func'] == 'pec':
        continue
    if prev is None:
        prev = e
        continue
    # ensure prev is not pec
    if prev['func'] == 'pec':
        prev = e
        continue
    interval = e['ts'] - prev['ts']
    rows.append({
        'function': e['func'],
        'time_s': round(interval, 3),
        'time_min': round(interval/60.0, 3),
        'cores': (e['cores'] if e['cores'] is not None else '')
    })
    prev = e

with out_path.open('w', newline='') as f:
    w = csv.DictWriter(f, fieldnames=['function','time_s','time_min','cores'])
    w.writeheader()
    w.writerows(rows)

print(f'Wrote {out_path} with {len(rows)} rows')