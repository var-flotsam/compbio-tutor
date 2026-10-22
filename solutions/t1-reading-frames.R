# Track 1: six reading frames
suppressPackageStartupMessages(library(Biostrings))

lines <- readLines("data/t1-reading-frames.fasta")
seq <- paste(lines[!startsWith(lines, ">")], collapse = "")

# Translate the complete codons of a sequence, starting at its first base.
translate_codons <- function(s) {
  starts <- seq(1, nchar(s) - 2, by = 3)
  paste(GENETIC_CODE[substring(s, starts, starts + 2)], collapse = "")
}

rc <- as.character(reverseComplement(DNAString(seq)))

frames <- c(
  "+1" = translate_codons(substring(seq, 1)),
  "+2" = translate_codons(substring(seq, 2)),
  "+3" = translate_codons(substring(seq, 3)),
  "-1" = translate_codons(substring(rc, 1)),
  "-2" = translate_codons(substring(rc, 2)),
  "-3" = translate_codons(substring(rc, 3))
)
cat(paste(names(frames)[!grepl("*", frames, fixed = TRUE)], collapse = ", "), "\n")
