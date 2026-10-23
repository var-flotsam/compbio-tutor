# Track 1: translation
# Needs Biostrings for the genetic code table (run setup/check_setup.R if missing).
suppressPackageStartupMessages(library(Biostrings))

lines <- readLines("data/t1-translate.fasta")
seq <- paste(lines[!startsWith(lines, ">")], collapse = "")

# 1. Cut the sequence into codons.
starts <- seq(1, nchar(seq) - 2, by = 3)
codons <- substring(seq, starts, starts + 2)

# 2. Look up each codon in the standard genetic code.
aa <- GENETIC_CODE[codons]

# 3. Keep the amino acids before the first stop ("*") and join them.
protein <- paste(aa[seq_len(which(aa == "*")[1] - 1)], collapse = "")
answer <- protein
answer
