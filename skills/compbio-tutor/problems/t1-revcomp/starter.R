# Track 1: reverse complement

lines <- readLines("data/t1-revcomp.fasta")
seq <- paste(lines[!startsWith(lines, ">")], collapse = "")

# 1. Swap each base for its pairing partner.
paired <- ___

# 2. Write the result 5' to 3'.
answer <- ___
answer
