# Reference sequence functions used to compute expected answers.
# Base R only, so the tutor runs before any package is installed.

.bases <- c("T", "C", "A", "G")
.amino <- "FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG"

# Standard genetic code (NCBI translation table 1), built from the usual TCAG order.
codon_table <- local({
  codons <- as.vector(t(outer(
    as.vector(t(outer(.bases, .bases, paste0))), .bases, paste0
  )))
  stats::setNames(strsplit(.amino, "")[[1]], codons)
})
start_codon <- "ATG"
stop_codons <- c("TAA", "TAG", "TGA")

gc_fraction <- function(seq) {
  if (!nzchar(seq)) stop("empty sequence")
  letters <- strsplit(seq, "")[[1]]
  sum(letters %in% c("G", "C")) / length(letters)
}

count_base <- function(seq, base) {
  sum(strsplit(seq, "")[[1]] == base)
}

complement <- function(seq) chartr("ACGT", "TGCA", seq)

reverse_string <- function(seq) paste(rev(strsplit(seq, "")[[1]]), collapse = "")

reverse_complement <- function(seq) reverse_string(complement(seq))

codons_of <- function(seq) {
  n <- nchar(seq)
  if (n < 3) return(character(0))
  starts <- seq(1, n - 2, by = 3)
  substring(seq, starts, starts + 2)
}

# Translate codon by codon; a trailing partial codon is ignored.
translate_dna <- function(seq, to_stop = FALSE) {
  aa <- unname(codon_table[codons_of(chartr("U", "T", seq))])
  if (to_stop) {
    first_stop <- match("*", aa)
    if (!is.na(first_stop)) aa <- aa[seq_len(first_stop - 1)]
  }
  paste(aa, collapse = "")
}

# Frames +1, +2, +3 on the given strand, then -1, -2, -3 on the reverse complement.
six_frame_translations <- function(seq) {
  rc <- reverse_complement(seq)
  frames <- c(
    vapply(1:3, function(k) translate_dna(substring(seq, k)), ""),
    vapply(1:3, function(k) translate_dna(substring(rc, k)), "")
  )
  stats::setNames(frames, c("+1", "+2", "+3", "-1", "-2", "-3"))
}

# ATG...stop ORFs on both strands, as a data frame. Coordinates are 1-based on
# the forward strand; `end` is the last base of the stop codon. Nested ORFs (an
# ATG inside another ORF in the same frame) are included.
find_orfs <- function(seq) {
  n <- nchar(seq)
  rows <- list()
  for (strand in c("+", "-")) {
    s <- if (strand == "+") seq else reverse_complement(seq)
    for (i in seq_len(max(n - 2, 0))) {
      if (substring(s, i, i + 2) != start_codon) next
      for (j in seq(i, n - 2, by = 3)) {
        if (substring(s, j, j + 2) %in% stop_codons) {
          protein <- translate_dna(substring(s, i, j - 1))
          if (strand == "+") {
            start <- i
            end <- j + 2
          } else {
            start <- n - (j + 2) + 1
            end <- n - i + 1
          }
          rows[[length(rows) + 1]] <- data.frame(
            strand = strand, start = start, end = end, protein = protein,
            length_nt = end - start + 1, stringsAsFactors = FALSE
          )
          break
        }
      }
    }
  }
  if (length(rows) == 0) {
    return(data.frame(
      strand = character(0), start = integer(0), end = integer(0),
      protein = character(0), length_nt = integer(0), stringsAsFactors = FALSE
    ))
  }
  do.call(rbind, rows)
}

random_dna <- function(length, gc = 0.5) {
  probs <- c((1 - gc) / 2, gc / 2, gc / 2, (1 - gc) / 2)
  paste(sample(c("A", "C", "G", "T"), length, replace = TRUE, prob = probs), collapse = "")
}

to_fasta <- function(name, seq, width = 60) {
  starts <- seq(1, max(nchar(seq), 1), by = width)
  lines <- c(paste0(">", name), substring(seq, starts, pmin(starts + width - 1, nchar(seq))))
  paste0(paste(lines, collapse = "\n"), "\n")
}

parse_fasta <- function(text) {
  lines <- trimws(strsplit(text, "\n", fixed = TRUE)[[1]])
  lines <- lines[nzchar(lines)]
  if (length(lines) == 0 || !startsWith(lines[1], ">")) {
    stop("FASTA text must start with a '>' header line")
  }
  is_header <- startsWith(lines, ">")
  record <- cumsum(is_header)
  names <- sub("^>(\\S*).*$", "\\1", lines[is_header])
  seqs <- vapply(seq_along(names), function(k) {
    toupper(paste(lines[record == k & !is_header], collapse = ""))
  }, "")
  stats::setNames(seqs, names)
}
