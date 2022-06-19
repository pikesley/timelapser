from pathlib import Path


def make_cron_lines(photos_per_minute):
    """Make the cron lines."""
    delay = 0
    lines = []
    while round(delay) < 60:
        lines.append(
            f"* * * * * pi python {Path.cwd()}/scripts/take_still.py {int(delay)}\n"
        )
        delay = delay + (60 / photos_per_minute)

    return lines


if __name__ == "__main__":
    cron_lines = make_cron_lines(
        int(Path("conf/photos-per-minute").read_text(encoding="UTF-8"))
    )
    Path("/etc", "cron.d", Path.cwd().stem).write_text(
        "".join(cron_lines),
        encoding="UTF-8",
    )
