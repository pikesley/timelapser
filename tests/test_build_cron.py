from scripts.build_cron import make_cron_lines


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
