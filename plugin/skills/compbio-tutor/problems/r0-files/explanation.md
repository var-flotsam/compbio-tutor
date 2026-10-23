# Reading a sequence file: worked explanation

**Method.** Drop the header, join the rest, and count the letters:

```r
lines <- readLines("data/r0-files.fasta")
seq_lines <- lines[!startsWith(lines, ">")]
seq <- paste(seq_lines, collapse = "")
nchar(seq)
```

**What you used.** `readLines()` reads relative to the working directory, which
is why the lessons run from your course folder. `!` turns TRUE into FALSE, so the
header is dropped. `paste(..., collapse = "")` joins lines with nothing between
them.

**Common slips.** Counting every line, header included, adds the header's
characters. `length(lines)` counts lines, not bases. Taking only the first
sequence line misses the rest of the sequence.

**The biology.** FASTA dates from a 1985 sequence-comparison program and is still
the most common way to share DNA and protein sequences. Databases such as Ensembl
let you download any gene as a FASTA file.

**Next.** The last basics problem teaches you to write your own functions and
loops.
