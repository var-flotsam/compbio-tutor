# Track 0: counting
# Fill in the parts marked ___, save the file, then ask the tutor to run it.

seq <- readLines("data/r0-counting.txt")

# 1. Split into single letters.
letters_vec <- strsplit(seq, "")[[1]]
head(letters_vec)

# 2. Count each base.
counts <- ___
print(counts)

# 3. How many times does the most common base appear?
___
