# gold-star

A simple habit tracker. Each day you do well, give yourself a gold
star. _This works only if "number go up" is enough to motivate you._

It display a GitHub contribution history like chart along with stats
about your streaks and overall commitment to the habit. The data is
stored in a `tsv`, one for each habit you wish to track.

```
    Sep        Oct       Nov
Mon 🔲 🔲 🟩 🟥 🟩 🔲 🟩 🟩 🟩 🔲
Tue 🔲 🔲 🟩 🟩 🟩 🟩 🔲 🟩 🟩 🟥
Wed 🔲 🔲 🟩 🟩 🟩 🔲 🟩 🟩 🟩 🟥
Thu 🔲 🔲 🟩 🟩 🟥 🟩 🟩 🟩 🟩 🟩
Fri 🔲 🔲 🟩 🟩 🟥 🟩 🟥 🟩 🟩 🟩
Sat 🔲 🔲 🟩 🟩 🟩 🟩 🟥 🟩 🟥 🟩
Sun 🔲 🔲 🟩 🟩 🟩 🟩 🟥 🟩 🔲

stars:
  period  41/50 82.0%
  all     41/50 82.0%
streak:
  active  3
  period  12
  all     12
```

## Usage

```
Log: date<TAB>1|0[<TAB>note], one file per habit. Append-only; the last line
for a date wins. Every line is a record, a comment starting with #, or blank.

  star                           show the last 10 weeks of log.tsv
  star yes [note]                give today a star (also: y, 1)
  star no [note]                 record today as no star (also: n, 0)
  star -d yesterday yes          record another day (or -d 2026-11-12)
  star -f run.tsv -f read.tsv    show several habits
  star -p 4m -e 2026-01-01       show a period of 4 months ending in the week of Jan 1

positional arguments:
  yes|no
  note

optional arguments:
  -h, --help            show this help message and exit
  -f FILE, --file FILE  log file; repeat to show several
  -p PERIOD, --period PERIOD
                        Nd, Nw, Nm or Ny (default: 10w)
  -e END, --end END     end date (default: today)
  -d DAY, --day DAY     record date (default: today)
```
