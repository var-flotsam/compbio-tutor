# Track 1: reverse complement

lines <- readLines("data/t1-revcomp.fasta")
seq <- paste(lines[!startsWith(lines, ">")], collapse = "")

# 1. Swap each base for its pairing partner.
paired <- chartr("ACGT", "TGCA", seq)

# 2. Write the result 5' to 3'.
answer <- paste(rev(strsplit(paired, "")[[1]]), collapse = "")
answer
