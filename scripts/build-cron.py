import sys
from pathlib import Path

photos_per_minute = int(sys.argv[1])

delay = 0
lines = []
while round(delay) < 60:
    lines.append(f"* * * * * pi python {Path.cwd()}/scripts/take-still.py {int(delay)}\n")
    delay = delay + (60 / photos_per_minute)

Path("/etc", "cron.d", Path.cwd().stem).write_text("".join(lines))
