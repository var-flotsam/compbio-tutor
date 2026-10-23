# Track 1: right answers pass, known mistakes get their code, others fail.
seeds <- 1:25

test_that("datasets are reproducible and differ between seeds", {
  for (p in all_problems) {
    expect_identical(make_dataset(p, 3), make_dataset(p, 3))
    expect_false(identical(make_dataset(p, 1), make_dataset(p, 2)))
  }
})

test_that("gc content", {
  p <- all_problems[["t1-gc-content"]]
  for (seed in seeds) {
    r <- record(p, seed)
    gc <- gc_fraction(r$seq)
    g <- count_base(r$seq, "G") / nchar(r$seq)
    expect_equal(grade_problem(p, sprintf("%.4f", gc), r$text)$status, "correct")
    expect_equal(grade_problem(p, sprintf("%.2f", gc * 100), r$text)$code, "percent_not_fraction")
    expect_equal(grade_problem(p, sprintf("%.4f", 1 - gc), r$text)$code, "at_content")
    expect_equal(grade_problem(p, sprintf("%.4f", g), r$text)$code, "g_only")
    expect_equal(grade_problem(p, sprintf("%.4f", gc + 0.01), r$text)$status, "incorrect")
    expect_equal(grade_problem(p, "about half", r$text)$status, "invalid")
  }
})

test_that("reverse complement", {
  p <- all_problems[["t1-revcomp"]]
  for (seed in seeds) {
    r <- record(p, seed)
    rc <- reverse_complement(r$seq)
    expect_equal(grade_problem(p, rc, r$text)$status, "correct")
    expect_equal(grade_problem(p, tolower(rc), r$text)$status, "correct")
    expect_equal(grade_problem(p, reverse_string(r$seq), r$text)$code, "reverse_not_complement")
    expect_equal(grade_problem(p, complement(r$seq), r$text)$code, "complement_not_reverse")
    expect_equal(grade_problem(p, r$seq, r$text)$code, "unchanged")
    expect_equal(grade_problem(p, substring(rc, 2), r$text)$code, "wrong_length")
    expect_equal(grade_problem(p, "ATGN", r$text)$status, "invalid")
  }
})

test_that("translation", {
  p <- all_problems[["t1-translate"]]
  for (seed in seeds) {
    r <- record(p, seed)
    protein <- translate_dna(r$seq, to_stop = TRUE)
    expect_true(startsWith(protein, "M"))
    expect_equal(nchar(protein), nchar(r$seq) / 3 - 1)
    expect_equal(grade_problem(p, protein, r$text)$status, "correct")
    expect_equal(grade_problem(p, paste0(protein, "*"), r$text)$code, "included_stop")
    expect_equal(grade_problem(p, substring(protein, 2), r$text)$code, "wrong_length")
  }
})

test_that("reading frames", {
  p <- all_problems[["t1-reading-frames"]]
  for (seed in seeds) {
    r <- record(p, seed)
    frames <- six_frame_translations(r$seq)
    open <- names(frames)[!grepl("*", frames, fixed = TRUE)]
    expect_equal(grade_problem(p, paste(rev(open), collapse = ", "), r$text)$status, "correct")
    fwd <- open[startsWith(open, "+")]
    expect_equal(grade_problem(p, paste(fwd, collapse = ", "), r$text)$code, "forward_frames_only")
    closed <- setdiff(names(frames), open)
    expect_equal(grade_problem(p, paste(closed, collapse = ", "), r$text)$status, "incorrect")
  }
})

test_that("longest ORF", {
  p <- all_problems[["t1-longest-orf"]]
  reverse_hits <- 0
  for (seed in 1:60) {
    r <- record(p, seed)
    orfs <- find_orfs(r$seq)
    orfs <- orfs[order(-orfs$length_nt), ]
    best <- orfs$protein[1]
    expect_equal(grade_problem(p, best, r$text)$status, "correct")
    expect_equal(grade_problem(p, paste0(best, "*"), r$text)$code, "included_stop")
    expect_equal(grade_problem(p, substring(best, 2), r$text)$status, "incorrect")
    fwd <- orfs[orfs$strand == "+", ]
    if (orfs$strand[1] == "-" && nrow(fwd) > 0) {
      expect_equal(grade_problem(p, fwd$protein[1], r$text)$code, "forward_strand_only")
      reverse_hits <- reverse_hits + 1
    }
  }
  expect_gt(reverse_hits, 0)
})

test_that("random wrong answers never pass", {
  set.seed(0)
  for (p in all_problems) {
    text <- make_dataset(p, 7)
    target <- problem_expected(p, text)$value
    for (i in 1:50) {
      guess <- switch(p$grader$kind,
        numeric = sprintf("%.4f", stats::runif(1)),
        set = paste(sample(c("+1", "+2", "+3", "-1", "-2", "-3"), 3), collapse = ","),
        sequence = if (p$grader$alphabet == "protein") {
          paste0("M", paste(sample(alphabets$protein[1:20], 30, TRUE), collapse = ""))
        } else {
          random_dna(sample(5:80, 1))
        }
      )
      v <- grade_problem(p, guess, text)
      # A pass is only acceptable if the random guess really is the answer.
      lucky <- setequal(toupper(parse_items(guess)), toupper(unlist(target)))
      expect_true(v$status != "correct" || lucky, info = paste(p$id, guess))
    }
  }
})
