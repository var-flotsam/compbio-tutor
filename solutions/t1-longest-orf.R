# Track 1: longest open reading frame
suppressPackageStartupMessages(library(Biostrings))

lines <- readLines("data/t1-longest-orf.fasta")
seq <- paste(lines[!startsWith(lines, ">")], collapse = "")
stops <- c("TAA", "TAG", "TGA")

# Return every ORF (ATG ... up to, not including, the stop) on one strand.
find_orfs <- function(s) {
  orfs <- character(0)
  for (start in gregexpr("ATG", s)[[1]]) {
    if (start < 0) next
    pos <- start
    while (pos + 2 <= nchar(s)) {
      codon <- substring(s, pos, pos + 2)
      if (codon %in% stops) {
        orfs <- c(orfs, substring(s, start, pos - 1))
        break
      }
      pos <- pos + 3
    }
  }
  orfs
}

all_orfs <- c(find_orfs(seq), find_orfs(as.character(reverseComplement(DNAString(seq)))))
longest <- all_orfs[which.max(nchar(all_orfs))]
cat(as.character(translate(DNAString(longest))), "\n")
