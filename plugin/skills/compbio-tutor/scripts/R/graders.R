# Deterministic answer graders.
#
# Every grader takes the student's raw answer text and an expected answer
# (`expected(value, diagnostics)`) and returns a verdict
# (`verdict(status, code, message, details)`). Messages shown to students never
# contain the expected answer. Base R only.

alphabets <- list(
  dna = c("A", "C", "G", "T"),
  rna = c("A", "C", "G", "U"),
  # 20 standard amino acids plus "*" for a stop codon.
  protein = c(strsplit("ACDEFGHIKLMNPQRSTVWY", "")[[1]], "*")
)

# A recognised wrong answer and the feedback it earns. `tolerance` (numeric
# graders only) overrides the problem's tolerance, e.g. for a percentage
# reported to 2 decimals.
diagnostic <- function(code, value, message, tolerance = NULL) {
  list(code = code, value = value, message = message, tolerance = tolerance)
}

expected <- function(value, diagnostics = list()) {
  list(value = value, diagnostics = diagnostics)
}

verdict <- function(status = c("correct", "partial", "incorrect", "invalid"),
                    code = "", message = "", details = list()) {
  list(status = match.arg(status), code = code, message = message, details = details)
}

# Signal that an answer couldn't be parsed. The message is safe to show.
answer_format_error <- function(message) {
  stop(structure(
    class = c("answer_format_error", "error", "condition"),
    list(message = message, call = NULL)
  ))
}

interval <- function(chrom, start, end) list(chrom = chrom, start = start, end = end)

# --- parsing helpers --------------------------------------------------------

parse_number <- function(text) {
  cleaned <- gsub(",", "", trimws(text))
  if (endsWith(cleaned, "%")) {
    answer_format_error(
      "Please give a plain number without a % sign, in the format the problem asks for."
    )
  }
  if (!grepl("^[-+]?([0-9]+\\.?[0-9]*|\\.[0-9]+)([eE][-+]?[0-9]+)?$", cleaned)) {
    answer_format_error(sprintf("I couldn't read '%s' as a number.", trimws(text)))
  }
  as.numeric(cleaned)
}

# Upper-case, drop whitespace and digits (as in numbered FASTA lines), check letters.
normalize_sequence <- function(text, alphabet) {
  seq <- toupper(gsub("[[:space:][:digit:]]", "", text))
  if (!nzchar(seq)) answer_format_error("The answer is empty. Please paste the sequence.")
  bad <- sort(setdiff(unique(strsplit(seq, "")[[1]]), alphabets[[alphabet]]))
  if (length(bad) > 0) {
    answer_format_error(sprintf(
      "These characters aren't valid in a %s sequence: %s.",
      toupper(alphabet), paste(bad, collapse = ", ")
    ))
  }
  seq
}

# Split a list answer on commas, semicolons or whitespace.
parse_items <- function(text) {
  items <- strsplit(trimws(text), "[,;[:space:]]+")[[1]]
  items <- items[nzchar(items)]
  if (length(items) == 0) answer_format_error("The answer is empty. Please list the items.")
  items
}

parse_interval <- function(text) {
  pattern <- paste0(
    "^\\s*(?:(?:chr)?([0-9]{1,2}|X|Y|MT?)\\s*:\\s*)?",
    "([0-9][0-9,._]*)\\s*(?:-|–|to)\\s*([0-9][0-9,._]*)\\s*$"
  )
  m <- regmatches(text, regexec(pattern, text, perl = TRUE, ignore.case = TRUE))[[1]]
  if (length(m) == 0) {
    answer_format_error(
      "Please write the interval as chromosome:start-end, for example 7:30.5-34.2."
    )
  }
  num <- function(x) as.numeric(gsub("[,_]", "", x))
  start <- num(m[3])
  end <- num(m[4])
  if (is.na(start) || is.na(end)) answer_format_error("I couldn't read those positions.")
  if (end < start) answer_format_error("The end of the interval is smaller than the start.")
  interval(if (nzchar(m[2])) toupper(m[2]) else NA_character_, start, end)
}

# --- graders ----------------------------------------------------------------

match_diagnostic <- function(exp, same) {
  for (diag in exp$diagnostics) {
    if (same(diag)) return(verdict("incorrect", diag$code, diag$message))
  }
  NULL
}

grade_numeric <- function(answer, exp, tolerance) {
  value <- parse_number(answer)
  close <- function(target, tol) is.numeric(target) && abs(value - target) <= tol
  if (close(exp$value, tolerance)) return(verdict("correct"))
  diag <- match_diagnostic(exp, function(d) {
    close(d$value, if (is.null(d$tolerance)) tolerance else d$tolerance)
  })
  if (!is.null(diag)) return(diag)
  verdict("incorrect", "wrong_value", "That number isn't right yet.")
}

grade_exact <- function(answer, exp, case_sensitive = FALSE) {
  norm <- function(x) {
    x <- gsub("\\s+", " ", trimws(as.character(x)))
    if (case_sensitive) x else tolower(x)
  }
  given <- norm(answer)
  if (!nzchar(given)) answer_format_error("The answer is empty.")
  if (identical(given, norm(exp$value))) return(verdict("correct"))
  diag <- match_diagnostic(exp, function(d) identical(norm(d$value), given))
  if (!is.null(diag)) return(diag)
  verdict("incorrect", "wrong_value", "That isn't the answer yet.")
}

grade_sequence <- function(answer, exp, alphabet) {
  given <- normalize_sequence(answer, alphabet)
  target <- exp$value
  if (identical(given, target)) return(verdict("correct"))
  diag <- match_diagnostic(exp, function(d) identical(d$value, given))
  if (!is.null(diag)) return(diag)
  if (nchar(given) != nchar(target)) {
    relation <- if (nchar(given) < nchar(target)) "shorter" else "longer"
    return(verdict(
      "incorrect", "wrong_length",
      sprintf("Your sequence is %s than expected.", relation),
      list(length_given = nchar(given))
    ))
  }
  diffs <- which(strsplit(given, "")[[1]] != strsplit(target, "")[[1]])
  verdict(
    "incorrect", "mismatch",
    sprintf(
      "The length is right, but %d position(s) differ. The first difference is at position %d.",
      length(diffs), diffs[1]
    ),
    list(mismatches = length(diffs), first_mismatch = diffs[1])
  )
}

grade_set <- function(answer, exp, case_sensitive = FALSE) {
  norm <- function(x) unique(if (case_sensitive) as.character(x) else tolower(x))
  given <- norm(parse_items(answer))
  target <- norm(exp$value)
  same_set <- function(a, b) length(a) == length(b) && all(a %in% b)
  if (same_set(given, target)) return(verdict("correct"))
  diag <- match_diagnostic(exp, function(d) same_set(norm(d$value), given))
  if (!is.null(diag)) return(diag)
  missing <- length(setdiff(target, given))
  extra <- length(setdiff(given, target))
  parts <- c(
    if (missing > 0) sprintf("%d item(s) are missing", missing),
    if (extra > 0) sprintf("%d item(s) don't belong", extra)
  )
  status <- if (length(intersect(given, target)) > 0) "partial" else "incorrect"
  verdict(
    status, "set_mismatch", paste0(paste(parts, collapse = "; "), "."),
    list(missing = missing, extra = extra)
  )
}

grade_choice <- function(answer, exp, options) {
  given <- toupper(gsub("^[(. ]+|[). ]+$", "", trimws(answer)))
  valid <- toupper(options)
  if (!given %in% valid) {
    answer_format_error(sprintf("Please answer with one of: %s.", paste(valid, collapse = ", ")))
  }
  if (identical(given, toupper(exp$value))) return(verdict("correct"))
  diag <- match_diagnostic(exp, function(d) identical(toupper(d$value), given))
  if (!is.null(diag)) return(diag)
  verdict("incorrect", "wrong_choice", "That's not the best choice.")
}

# Correct when both ends are within `tolerance` of the expected ends.
grade_interval <- function(answer, exp, tolerance) {
  given <- parse_interval(answer)
  target <- exp$value
  if (!is.na(target$chrom) && is.na(given$chrom)) {
    answer_format_error("Please include the chromosome, for example 7:30.5-34.2.")
  }
  if (!is.na(target$chrom) && given$chrom != target$chrom) {
    diag <- match_diagnostic(exp, function(d) identical(d$value$chrom, given$chrom))
    if (!is.null(diag)) return(diag)
    return(verdict(
      "incorrect", "wrong_chromosome", "That interval is on a different chromosome."
    ))
  }
  if (abs(given$start - target$start) <= tolerance && abs(given$end - target$end) <= tolerance) {
    return(verdict("correct"))
  }
  if (given$start > target$end || target$start > given$end) {
    return(verdict(
      "incorrect", "no_overlap", "Your interval doesn't overlap the region we're after."
    ))
  }
  given_width <- given$end - given$start
  target_width <- target$end - target$start
  if (given_width < target_width - 2 * tolerance) {
    verdict("partial", "interval_too_narrow", "Your interval is too narrow.")
  } else if (given_width > target_width + 2 * tolerance) {
    verdict("partial", "interval_too_wide", "Your interval is too wide.")
  } else {
    verdict("partial", "interval_shifted", "Your interval is about the right width but shifted.")
  }
}

# Check the first `top_k` items of the student's ranking.
grade_ranking <- function(answer, exp, top_k, ordered = FALSE) {
  given <- tolower(parse_items(answer))
  if (length(given) < top_k) {
    answer_format_error(sprintf("Please list at least %d items, best first.", top_k))
  }
  head <- given[seq_len(top_k)]
  target <- tolower(exp$value)[seq_len(top_k)]
  right <- if (ordered) identical(head, target) else setequal(head, target)
  if (right) return(verdict("correct"))
  hits <- length(intersect(head, target))
  if (hits > 0) {
    return(verdict(
      "partial", "ranking_partial", sprintf("%d of your top %d are right.", hits, top_k),
      list(hits = hits)
    ))
  }
  verdict("incorrect", "ranking_wrong", sprintf("None of your top %d are right yet.", top_k))
}

graders <- list(
  numeric = grade_numeric,
  exact = grade_exact,
  sequence = grade_sequence,
  set = grade_set,
  choice = grade_choice,
  interval = grade_interval,
  ranking = grade_ranking
)
