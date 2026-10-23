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
