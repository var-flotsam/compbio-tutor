# Track 0: R basics

The R a student needs for the course, taught on small DNA-flavoured data. Each
problem is short, graded like any other, and gives every student their own data.

| id | Title | Teaches |
|---|---|---|
| r0-variables | Your first R script: numbers and variables | Running a script, `<-`, arithmetic, `round()`, `cat()` |
| r0-vectors | Many numbers at once: vectors | `c()`, `length()`, comparisons, `sum()` of TRUE/FALSE |
| r0-strings | Working with text: strings | `readLines()`, `nchar()`, `substr()`, `toupper()` |
| r0-counting | Counting letters with table() | `strsplit()`, `table()`, `max()` |
| r0-files | Reading a sequence file | FASTA format, `startsWith()`, `!`, `paste(collapse = "")` |
| r0-functions | Your own functions and loops | `function()`, `if`/`else`, `for` loops, `grepl()` |

## How to use it

- A student who has never written R starts with r0-variables and goes in order.
- A student who knows some R can skip it. Every Track 1 problem lists the R basics
  it uses (`show` prints them as solved or not done yet). If one isn't done, offer
  it first as a short warm-up, and let the student decline.
- Teach R syntax freely, with small examples on other data. The grading rules are
  the same as for every track: the student writes the code that gets the answer.
- Data frames and plotting come later, with tracks 2 and 3.
