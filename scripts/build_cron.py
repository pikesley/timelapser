from pathlib import Path

photos_per_minute = int(Path("conf/photos-per-minute").read_text(encoding="UTF-8"))

DELAY = 0
lines = []
while round(DELAY) < 60:
    lines.append(
        f"* * * * * pi python {Path.cwd()}/scripts/take_still.py {int(DELAY)}\n"
    )
    DELAY = DELAY + (60 / photos_per_minute)

Path("/etc", "cron.d", Path.cwd().stem).write_text("".join(lines), encoding="UTF-8")
