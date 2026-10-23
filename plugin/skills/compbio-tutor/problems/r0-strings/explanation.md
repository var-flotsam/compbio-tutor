# Strings: worked explanation

**Method.** Read the line, cut out positions 5 to 14, and make it upper case:

```r
seq <- readLines("data/r0-strings.txt")
part <- substr(seq, 5, 14)
toupper(part)
```

**What you used.** A string is text in quotes. `substr()` includes both the start
and the stop, so 5 to 14 is 10 letters. You can nest calls:
`toupper(substr(seq, 5, 14))` does both steps at once.

**Common slips.** Starting at 4 or 6 shifts the window by one letter. Using 15 as
the stop gives 11 letters. Forgetting `toupper()` leaves the letters lowercase.

**The biology.** Biologists number bases from 1, just like R, so position 5 in a
paper means the same as `substr(seq, 5, 5)`. Some languages, such as Python,
count from 0 instead.

**Next.** The next problem splits a sequence into single letters and counts them.
