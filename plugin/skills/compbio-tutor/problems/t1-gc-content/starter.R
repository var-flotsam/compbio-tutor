# Track 1: GC content
# Run this from your project folder. Fill in the parts marked ___.

lines <- readLines("data/t1-gc-content.fasta")

# 1. Keep only the sequence lines (drop the header that starts with ">").
seq_lines <- lines[!startsWith(lines, ">")]

# 2. Join them into one string.
seq <- paste(seq_lines, collapse = "")

# 3. Split into single letters and count each base.
bases <- strsplit(seq, "")[[1]]
counts <- ___

# 4. GC content = (G + C) / total length.
gc <- ___
round(gc, 4)
