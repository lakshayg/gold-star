#!/usr/bin/env python3
"""star: a gold-star chart. One bit a day: did I earn a star?

Log: date<TAB>1|0[<TAB>note], one file per habit. Append-only; the last line
for a date wins. Every line is a record, a comment starting with #, or blank.

  star                           show the last 10 weeks of log.tsv
  star yes [note]                give today a star (also: y, 1)
  star no [note]                 record today as no star (also: n, 0)
  star -d yesterday yes          record another day (or -d 2026-11-12)
  star -f run.tsv -f read.tsv    show several habits
  star -p 4m -e 2026-01-01       show a period of 4 months ending in the week of Jan 1
"""

import argparse
import calendar
import re
import sys
from collections.abc import Iterable
from datetime import date, timedelta
from itertools import groupby
from pathlib import Path

DAY = timedelta(days=1)
WEEK = timedelta(weeks=1)
TODAY = date.today()

VALUES = dict.fromkeys(("yes", "y", "1"), "1") | dict.fromkeys(("no", "n", "0"), "0")
CELL = {True: "\033[32m■ ", False: "\033[31m■ ", None: "\033[30m□ "}
RESET = "\033[0m"
RECORD = re.compile(r"(\d{4}-\d\d-\d\d)\t([01])(?:\t.*)?")

Log = dict[date, bool]  # starred or not, by day


def day(s: str) -> date:
    """today | yesterday | YYYY-MM-DD"""
    return {"today": TODAY, "yesterday": TODAY - DAY}.get(s) or date.fromisoformat(s)


def period(s: str) -> tuple[int, str]:
    """Nd | Nw | Nm | Ny -> (count, unit)"""
    if m := re.fullmatch(r"([1-9]\d*)([dwmy])", s):
        return int(m[1]), m[2]
    raise ValueError(s)


def monday(d: date) -> date:
    return d - timedelta(days=d.weekday())


def weeks(count: int, unit: str, end: date) -> list[date]:
    """Mondays of the weeks spanning a period ending in the week of end."""
    last = monday(end)

    if unit == "w":
        first = last - (count - 1) * WEEK
    elif unit == "d":
        first = monday(end - (count - 1) * DAY)
    else:
        months = count * (12 if unit == "y" else 1)
        y, m = divmod(end.year * 12 + end.month - 1 - months, 12)
        d = min(end.day, calendar.monthrange(y, m + 1)[1])
        first = monday(date(y, m + 1, d) + DAY)

    return [first + i * WEEK for i in range((last - first) // WEEK + 1)]


def load(path: str) -> Log:
    """Load {date: starred}; later records win. Missing files are empty."""
    log = {}
    for n, line in enumerate(
        Path(path).read_text().splitlines() if Path(path).exists() else (), 1
    ):
        if not line.strip() or line.startswith("#"):
            continue
        try:
            m = RECORD.fullmatch(line)
            if m is None:
                raise ValueError
            log[date.fromisoformat(m[1])] = m[2] == "1"
        except ValueError:
            print(f"star: {path}:{n}: not a record: {line!r}", file=sys.stderr)
    return log


def rate(values: Iterable[bool]) -> str:
    values = list(values)
    if not values:
        return "-"
    return f"{sum(values)}/{len(values)} {sum(values) / len(values):.1%}"


def best(log: Log) -> int:
    """Longest run of consecutive starred days."""
    longest = run = 0
    prev = None

    for d in sorted(d for d, starred in log.items() if starred):
        run = run + 1 if prev == d - DAY else 1
        longest, prev = max(longest, run), d

    return longest


def active(log: Log) -> int:
    """Run of starred days up to today; an unset today doesn't break it."""
    d, run = (TODAY if TODAY in log else TODAY - DAY), 0

    while log.get(d):
        d, run = d - DAY, run + 1

    return run


def header(mondays: list[date]) -> str:
    """Name each month above its first full week, if it has at least two."""
    line = [" "] * (2 * len(mondays) + 2)
    full = (i for i, m in enumerate(mondays) if m.month == (m + 6 * DAY).month)

    for _, group in groupby(full, key=lambda i: mondays[i].strftime("%Y-%m")):
        cols = list(group)
        if len(cols) >= 2:
            i = cols[0]
            line[2 * i : 2 * i + 3] = mondays[i].strftime("%b")

    return "".join(line).rstrip()


def render(log: Log, mondays: list[date]) -> None:
    """One column per week, rows Monday..Sunday, then statistics."""
    grid = [m + r * DAY for m in mondays for r in range(7)]
    print("    " + header(mondays))

    for r, name in enumerate(calendar.day_abbr):
        cells = (CELL[log.get(d)] if d <= TODAY else "  " for d in grid[r::7])
        print(name, "".join(cells) + RESET)

    shown = {d: log[d] for d in grid if d in log and d <= TODAY}

    print("")
    print(f"stars:")
    print(f"  period  {rate(shown.values())}")
    print(f"  all     {rate(log.values())}")
    print(f"streak:")
    print(f"  active  {active(log)}")
    print(f"  period  {best(shown)}")
    print(f"  all     {best(log)}")


def main() -> None:
    p = argparse.ArgumentParser(
        prog="star",
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument(
        "-f", "--file", action="append", help="log file; repeat to show several"
    )
    p.add_argument(
        "-p",
        "--period",
        type=period,
        default="10w",
        help="Nd, Nw, Nm or Ny (default: 10w)",
    )
    p.add_argument(
        "-e", "--end", type=day, default="today", help="end date (default: today)"
    )
    p.add_argument(
        "-d", "--day", type=day, default="today", help="record date (default: today)"
    )
    p.add_argument("value", nargs="?", choices=VALUES, metavar="yes|no")
    p.add_argument("note", nargs="*")
    args = p.parse_args()

    files = args.file or ["log.tsv"]

    if args.value:
        if len(files) > 1:
            p.error("recording takes a single -f FILE")

        note = (
            " ".join(args.note).replace("\t", " ").replace("\n", " ").replace("\r", " ")
        )
        record = "\t".join(
            filter(None, (args.day.isoformat(), VALUES[args.value], note))
        )
        with open(files[0], "a") as f:
            print(record, file=f)

    count, unit = args.period
    mondays = weeks(count, unit, args.end)

    for i, path in enumerate(files):
        if len(files) > 1:
            print("\n" * (i > 0) + Path(path).stem)
        render(load(path), mondays)


if __name__ == "__main__":
    main()
