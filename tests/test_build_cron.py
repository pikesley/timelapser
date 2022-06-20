from pathlib import Path

from scripts.build_cron import make_cron_lines, retrieve_ppm, write_cron_lines


def test_build_cron():
    """Test it makes the cron lines."""
    assert make_cron_lines(1) == [
        "* * * * * pi python /opt/timelapser/scripts/take_still.py 0\n"
    ]

    assert make_cron_lines(4) == [
        "* * * * * pi python /opt/timelapser/scripts/take_still.py 0\n",
        "* * * * * pi python /opt/timelapser/scripts/take_still.py 15\n",
        "* * * * * pi python /opt/timelapser/scripts/take_still.py 30\n",
        "* * * * * pi python /opt/timelapser/scripts/take_still.py 45\n",
    ]

    assert make_cron_lines(7) == [
        "* * * * * pi python /opt/timelapser/scripts/take_still.py 0\n",
        "* * * * * pi python /opt/timelapser/scripts/take_still.py 8\n",
        "* * * * * pi python /opt/timelapser/scripts/take_still.py 17\n",
        "* * * * * pi python /opt/timelapser/scripts/take_still.py 25\n",
        "* * * * * pi python /opt/timelapser/scripts/take_still.py 34\n",
        "* * * * * pi python /opt/timelapser/scripts/take_still.py 42\n",
        "* * * * * pi python /opt/timelapser/scripts/take_still.py 51\n",
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
        "* * * * * pi python /opt/timelapser/scripts/take_still.py 0",
        "* * * * * pi python /opt/timelapser/scripts/take_still.py 20",
        "* * * * * pi python /opt/timelapser/scripts/take_still.py 40",
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
