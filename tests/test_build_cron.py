from pathlib import Path

from scripts.build_cron import make_cron_lines, retrieve_ppm, write_cron_lines

ROOT_DIR = Path.cwd()


def test_build_cron():
    """Test it makes the cron lines."""
    assert make_cron_lines(1) == [
        f"* * * * * pi python {ROOT_DIR}/scripts/take_still.py 0\n"
    ]

    assert make_cron_lines(4) == [
        f"* * * * * pi python {ROOT_DIR}/scripts/take_still.py 0\n",
        f"* * * * * pi python {ROOT_DIR}/scripts/take_still.py 15\n",
        f"* * * * * pi python {ROOT_DIR}/scripts/take_still.py 30\n",
        f"* * * * * pi python {ROOT_DIR}/scripts/take_still.py 45\n",
    ]

    assert make_cron_lines(7) == [
        f"* * * * * pi python {ROOT_DIR}/scripts/take_still.py 0\n",
        f"* * * * * pi python {ROOT_DIR}/scripts/take_still.py 8\n",
        f"* * * * * pi python {ROOT_DIR}/scripts/take_still.py 17\n",
        f"* * * * * pi python {ROOT_DIR}/scripts/take_still.py 25\n",
        f"* * * * * pi python {ROOT_DIR}/scripts/take_still.py 34\n",
        f"* * * * * pi python {ROOT_DIR}/scripts/take_still.py 42\n",
        f"* * * * * pi python {ROOT_DIR}/scripts/take_still.py 51\n",
    ]


def test_invalid_build_cron():
    """Test it gracefully handles bogus requests."""
    assert not make_cron_lines(0)
    assert not make_cron_lines(-1)
    assert not make_cron_lines("ten")


def test_write_cron_lines():
    """Test it writes out the cron lines."""
    write_cron_lines(make_cron_lines(3), "/tmp/cronlines")

    output = Path("/tmp/cronlines").read_text(encoding="UTF-8").split("\n")
    assert output[:3] == [
        f"* * * * * pi python {ROOT_DIR}/scripts/take_still.py 0",
        f"* * * * * pi python {ROOT_DIR}/scripts/take_still.py 20",
        f"* * * * * pi python {ROOT_DIR}/scripts/take_still.py 40",
    ]


def test_retrieve_ppm():
    """Test it retrieves the photos-per-minute value."""
    Path("/tmp/ppm").write_text("15", encoding="UTF-8")
    assert retrieve_ppm("/tmp/ppm") == 15


def test_bad_ppm():
    """Test it gracefully handles duff ppm strings."""
    Path("/tmp/ppm").write_text("dave", encoding="UTF-8")
    assert retrieve_ppm("/tmp/ppm") == 0


def test_no_ppm():
    """Test it gracefully handles a missing ppm file."""
    assert retrieve_ppm("/no/such/path") == 0
