test_that("every problem loads with the required parts", {
  expect_gte(length(all_problems), 5)
  for (p in all_problems) {
    expect_gte(length(p$hints), 3)
    expect_true(p$grader$kind %in% names(graders), info = p$id)
    expect_true(file.exists(file.path(p$folder, "explanation.md")), info = p$id)
    expect_true(file.exists(file.path(p$folder, p$starter)), info = p$id)
  }
})

test_that("problems are listed in teaching order", {
  expect_equal(names(all_problems)[1:5], c(
    "t1-gc-content", "t1-revcomp", "t1-translate", "t1-reading-frames", "t1-longest-orf"
  ))
})

test_that("a broken problem file is reported, not crashed on", {
  root <- withr::local_tempdir()
  bad <- file.path(root, "t1-bad")
  dir.create(bad)
  writeLines("problem <- list(id = 't1-other')", file.path(bad, "problem.R"))
  expect_error(load_all(root), class = "problem_error")
  writeLines("problem <- list(", file.path(bad, "problem.R"))
  expect_error(load_all(root), class = "problem_error")
})

test_that("starter code reads the student's data file and has blanks to fill", {
  for (p in all_problems) {
    starter <- paste(readLines(file.path(p$folder, p$starter)), collapse = "\n")
    expect_match(starter, sprintf("data/%s.fasta", p$id), fixed = TRUE, info = p$id)
    expect_match(starter, "___", fixed = TRUE, info = p$id)
  }
})

test_that("no answer appears in the text, hints or starter the student sees", {
  for (p in all_problems) {
    shown <- paste(
      p$background, p$prompt, p$goal, paste(p$hints, collapse = "\n"),
      paste(readLines(file.path(p$folder, p$starter)), collapse = "\n")
    )
    for (seed in c(1:10, 42L)) {
      e <- problem_expected(p, make_dataset(p, seed))
      for (v in unlist(e$value)) {
        v <- as.character(v)
        if (nchar(v) >= 6) expect_false(grepl(v, shown, fixed = TRUE), info = paste(p$id, seed))
      }
    }
  }
})
