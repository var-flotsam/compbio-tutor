# Track 1: six reading frames
library(Biostrings)

lines <- readLines("data/t1-reading-frames.fasta")
seq <- paste(lines[!startsWith(lines, ">")], collapse = "")

# Translate the complete codons of a sequence, starting at its first base.
translate_codons <- function(s) {
  starts <- seq(1, nchar(s) - 2, by = 3)
  paste(GENETIC_CODE[substring(s, starts, starts + 2)], collapse = "")
}

rc <- ___  # the reverse complement of seq

frames <- c(
  "+1" = translate_codons(substring(seq, 1)),
  "+2" = ___,
  "+3" = ___,
  "-1" = translate_codons(substring(rc, 1)),
  "-2" = ___,
  "-3" = ___
)
frames
answer <- names(frames)[___]  # the frames with no "*"
answer
