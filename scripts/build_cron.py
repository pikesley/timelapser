from pathlib import Path


def make_cron_lines(photos_per_minute):
    """Make the cron lines."""
    delay = 0
    lines = []

    if not isinstance(photos_per_minute, int) or photos_per_minute <= 0:
        return lines

    while round(delay) < 60:
        lines.append(
            f"* * * * * pi python {Path.cwd()}/scripts/take_still.py {int(delay)}\n"
        )
        delay = delay + (60 / photos_per_minute)

    return lines


def write_cron_lines(lines, path):
    """Write-out the cron lines."""
    Path(path).write_text("".join(lines), encoding="UTF-8")


def retrieve_ppm(path):
    """Retrieve the photos-per-minute value."""
    try:
        return int(Path(path).read_text(encoding="UTF-8"))
    except (ValueError, FileNotFoundError):
        return 0


if __name__ == "__main__":
    write_cron_lines(
        make_cron_lines(retrieve_ppm("conf/photos-per-minute")),
        f"/etc/cron.d/{Path.cwd().stem}",
    )
