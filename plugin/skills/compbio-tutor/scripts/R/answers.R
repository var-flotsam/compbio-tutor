# Per-problem datasets and expected answers.
#
# Each problem names a dataset builder and an answer function. Builders turn a
# seed into the text of the student's data file; answer functions turn that same
# text into an `expected()` value, including the wrong answers that common
# misconceptions produce.

datasets <- list()
answers <- list()

pick <- function(x) x[sample.int(length(x), 1)]
rand_int <- function(lo, hi) lo + sample.int(hi - lo + 1, 1) - 1

only_record <- function(text) {
  records <- parse_fasta(text)
  if (length(records) != 1) stop(sprintf("expected one FASTA record, found %d", length(records)))
  unname(records[[1]])
}

sense_codons <- function(include_start = TRUE) {
  codons <- names(codon_table)[codon_table != "*"]
  if (include_start) codons else setdiff(codons, start_codon)
}

# --- track 0: R basics -------------------------------------------------------

# Plain-text data: one value per line.
lines_text <- function(x) paste0(paste(x, collapse = "\n"), "\n")
text_lines <- function(text) {
  lines <- trimws(strsplit(text, "\n", fixed = TRUE)[[1]])
  lines[nzchar(lines)]
}

datasets[["r0.base_counts"]] <- function(seed) {
  set.seed(seed)
  lines_text(sample(60:160, 4))
}

answers[["r0.g_fraction"]] <- function(text) {
  counts <- as.numeric(text_lines(text))
  g <- counts[3]
  total <- sum(counts)
  expected(round(g / total, 4), list(
    diagnostic(
      "percent_not_fraction", round(100 * g / total, 4),
      "That looks like a percentage. The question asks for a fraction between 0 and 1.",
      tolerance = 0.01
    ),
    diagnostic(
      "wrong_base", round(counts[1] / total, 4),
      "That's the share of the first number. Which line holds the G count?"
    ),
    diagnostic(
      "g_over_rest", round(g / (total - g), 4),
      "Close: check what you divided by. The total includes the G bases too."
    )
  ))
}

datasets[["r0.gene_lengths"]] <- function(seed) {
  set.seed(seed)
  # Mostly long genes, a few short ones, and two of exactly 1000 bases.
  n_long <- rand_int(11, 14)
  lengths <- c(sample(1001:2500, n_long), sample(300:999, 18 - n_long), 1000, 1000)
  lines_text(sample(lengths))
}

answers[["r0.long_genes"]] <- function(text) {
  x <- as.numeric(text_lines(text))
  longer <- sum(x > 1000)
  expected(longer, list(
    diagnostic(
      "greater_or_equal", sum(x >= 1000),
      "That count includes genes that are exactly 1000 bases. The question asks for longer than 1000."
    ),
    diagnostic(
      "counted_shorter", sum(x < 1000),
      "That's the number of shorter genes. Check which way your comparison points."
    ),
    diagnostic(
      "counted_all", length(x),
      "That's how many genes there are in total. How can you keep only the long ones?"
    )
  ))
}

datasets[["r0.lower_dna"]] <- function(seed) {
  set.seed(seed)
  lines_text(tolower(random_dna(rand_int(30, 40))))
}

answers[["r0.substring_upper"]] <- function(text) {
  seq <- text_lines(text)[1]
  part <- function(from, to) toupper(substr(seq, from, to))
  expected(part(5, 14), list(
    diagnostic(
      "lowercase", substr(seq, 5, 14),
      "Right letters, but the question asks for capital letters. Is there an R function for that?"
    ),
    diagnostic(
      "off_by_one_early", part(4, 13),
      "You're one position early. In R, the first letter is position 1."
    ),
    diagnostic(
      "off_by_one_late", part(6, 15),
      "You're one position late. In R, the first letter is position 1."
    ),
    diagnostic(
      "one_too_many", part(5, 15),
      "You have 11 letters. substr(x, start, stop) includes both the start and the stop."
    )
  ))
}

datasets[["r0.count_dna"]] <- function(seed) {
  set.seed(seed)
  lines_text(random_dna(rand_int(90, 130), gc = stats::runif(1, 0.3, 0.7)))
}

answers[["r0.most_common_count"]] <- function(text) {
  seq <- text_lines(text)[1]
  counts <- table(strsplit(seq, "")[[1]])
  expected(max(counts), list(
    diagnostic(
      "least_common", min(counts),
      "That's how often the least common base appears. Which function gives the largest value?"
    ),
    diagnostic(
      "total_length", nchar(seq),
      "That's the length of the whole sequence. The question asks about one base."
    )
  ))
}

datasets[["r0.fasta_lines"]] <- function(seed) {
  set.seed(seed)
  to_fasta(paste0("read_", seed, " a DNA fragment"), random_dna(rand_int(250, 400)))
}

answers[["r0.total_bases"]] <- function(text) {
  lines <- text_lines(text)
  seq_lines <- lines[!startsWith(lines, ">")]
  expected(sum(nchar(seq_lines)), list(
    diagnostic(
      "counted_header", sum(nchar(lines)),
      "That includes the characters in the header line. Only the sequence lines hold bases."
    ),
    diagnostic(
      "counted_lines", length(lines),
      "That's the number of lines in the file. The question asks for bases."
    ),
    diagnostic(
      "counted_sequence_lines", length(seq_lines),
      "That's the number of sequence lines. How many letters are on them?"
    ),
    diagnostic(
      "first_line_only", nchar(seq_lines[1]),
      "That's the length of the first sequence line only. The sequence continues on the next lines."
    )
  ))
}

datasets[["r0.short_seqs"]] <- function(seed) {
  set.seed(seed)
  no_atg <- function(s) {
    while (grepl("ATG", s, fixed = TRUE)) s <- sub("ATG", "ACG", s, fixed = TRUE)
    s
  }
  insert_atg <- function(s) {
    pos <- rand_int(1, nchar(s) - 1)
    paste0(substr(s, 1, pos), "ATG", substr(s, pos + 1, nchar(s)))
  }
  seqs <- vapply(1:12, function(i) no_atg(random_dna(rand_int(15, 25))), "")
  # A few sequences contain ATG (one of them twice); most don't.
  k <- rand_int(3, 5)
  seqs[1:k] <- vapply(seqs[1:k], insert_atg, "")
  seqs[1] <- paste0("ATG", seqs[1])
  lines_text(sample(seqs))
}

answers[["r0.atg_sequences"]] <- function(text) {
  seqs <- text_lines(text)
  has <- grepl("ATG", seqs, fixed = TRUE)
  hits <- vapply(seqs, function(s) {
    n <- 0
    for (i in seq_len(max(nchar(s) - 2, 0))) if (substr(s, i, i + 2) == "ATG") n <- n + 1
    n
  }, numeric(1))
  expected(sum(has), list(
    diagnostic(
      "counted_occurrences", sum(hits),
      "That counts every ATG, and some sequences have more than one. The question asks how many sequences."
    ),
    diagnostic(
      "counted_without", sum(!has),
      "That's the number of sequences without ATG."
    )
  ))
}

# --- track 1: sequences -----------------------------------------------------

datasets[["t1.gc_dna"]] <- function(seed) {
  set.seed(seed)
  # GC between 35% and 65% spans typical mammalian regions.
  len <- rand_int(400, 600)
  seq <- random_dna(len, gc = stats::runif(1, 0.35, 0.65))
  to_fasta(paste0("sample_", seed), seq)
}

answers[["t1.gc_content"]] <- function(text) {
  seq <- only_record(text)
  gc <- gc_fraction(seq)
  n <- nchar(seq)
  expected(round(gc, 4), list(
    diagnostic(
      "percent_not_fraction", round(gc * 100, 4),
      "Your number looks like a percentage. The question asks for a fraction between 0 and 1.",
      tolerance = 0.01
    ),
    diagnostic(
      "at_content", round(1 - gc, 4),
      "That looks like the share of A and T. Which letters does the question ask about?"
    ),
    diagnostic(
      "g_only", round(count_base(seq, "G") / n, 4),
      "That matches counting only one of the two letters."
    ),
    diagnostic(
      "c_only", round(count_base(seq, "C") / n, 4),
      "That matches counting only one of the two letters."
    )
  ))
}

datasets[["t1.short_dna"]] <- function(seed) {
  set.seed(seed)
  to_fasta(paste0("fragment_", seed), random_dna(rand_int(60, 90)))
}

answers[["t1.reverse_complement"]] <- function(text) {
  seq <- only_record(text)
  expected(reverse_complement(seq), list(
    diagnostic(
      "reverse_not_complement", reverse_string(seq),
      paste(
        "You reversed the sequence. On the other strand, each base also pairs",
        "with a different base."
      )
    ),
    diagnostic(
      "complement_not_reverse", complement(seq),
      paste(
        "You paired each base correctly. Now think about which end of the",
        "other strand is its 5' end."
      )
    ),
    diagnostic("unchanged", seq, "That's the sequence you started with.")
  ))
}

datasets[["t1.coding_dna"]] <- function(seed) {
  set.seed(seed)
  sense <- sense_codons(include_start = FALSE)
  body <- sense[sample.int(length(sense), rand_int(15, 25), replace = TRUE)]
  to_fasta(paste0("cds_", seed), paste0(start_codon, paste(body, collapse = ""), pick(stop_codons)))
}

answers[["t1.translate"]] <- function(text) {
  seq <- only_record(text)
  protein <- translate_dna(seq, to_stop = TRUE)
  expected(protein, list(
    diagnostic(
      "included_stop", paste0(protein, "*"),
      "Nearly there. A stop codon ends the protein but doesn't add an amino acid."
    ),
    diagnostic(
      "wrong_frame_2", translate_dna(substring(seq, 2), to_stop = TRUE),
      "That looks like a translation starting one base late. Where does translation start?"
    ),
    diagnostic(
      "wrong_frame_3", translate_dna(substring(seq, 3), to_stop = TRUE),
      "That looks like a translation starting two bases late. Where does translation start?"
    ),
    diagnostic(
      "translated_revcomp", translate_dna(reverse_complement(seq), to_stop = TRUE),
      "That looks like a translation of the other strand."
    )
  ))
}

# Random DNA with one planted ORF, on a random strand, that is clearly the longest.
datasets[["t1.orf_dna"]] <- function(seed) {
  set.seed(seed)
  sense <- sense_codons()
  repeat {
    body <- sense[sample.int(length(sense), rand_int(40, 60), replace = TRUE)]
    orf <- paste0(start_codon, paste(body, collapse = ""), "TAA")
    if (stats::runif(1) < 0.5) orf <- reverse_complement(orf)
    seq <- paste0(random_dna(rand_int(30, 60)), orf, random_dna(rand_int(30, 60)))
    lens <- sort(find_orfs(seq)$length_nt, decreasing = TRUE)
    # Keep only datasets whose longest ORF is unique, so there is one right answer.
    if (length(lens) == 1 || (length(lens) >= 2 && lens[1] > lens[2] + 30)) {
      return(to_fasta(paste0("contig_", seed), seq))
    }
  }
}

answers[["t1.longest_orf_protein"]] <- function(text) {
  seq <- only_record(text)
  orfs <- find_orfs(seq)
  orfs <- orfs[order(-orfs$length_nt), ]
  best <- orfs[1, ]
  diagnostics <- list()
  forward <- orfs[orfs$strand == "+", ]
  if (best$strand == "-" && nrow(forward) > 0) {
    diagnostics[[1]] <- diagnostic(
      "forward_strand_only", forward$protein[1],
      paste(
        "That's the longest ORF on the strand you were given. Did you check the",
        "other strand too?"
      )
    )
  }
  diagnostics[[length(diagnostics) + 1]] <- diagnostic(
    "included_stop", paste0(best$protein, "*"), "Nearly there. Leave out the stop codon's '*'."
  )
  expected(best$protein, diagnostics)
}

# Short DNA where at least one frame on each strand is free of stop codons.
datasets[["t1.frames_dna"]] <- function(seed) {
  set.seed(seed)
  repeat {
    seq <- random_dna(45)
    open <- !grepl("*", six_frame_translations(seq), fixed = TRUE)
    if (any(open[1:3]) && any(open[4:6]) && !all(open)) {
      return(to_fasta(paste0("read_", seed), seq))
    }
  }
}

# Which of the six frames (+1..+3, -1..-3) translate with no stop codon at all?
answers[["t1.reading_frames"]] <- function(text) {
  seq <- only_record(text)
  frames <- six_frame_translations(seq)
  open_frames <- names(frames)[!grepl("*", frames, fixed = TRUE)]
  forward_only <- open_frames[startsWith(open_frames, "+")]
  diagnostics <- list()
  if (!identical(forward_only, open_frames)) {
    diagnostics[[1]] <- diagnostic(
      "forward_frames_only", forward_only,
      "You checked the three frames on the given strand. There are three more."
    )
  }
  expected(open_frames, diagnostics)
}
