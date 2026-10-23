json_field <- function(out, key) {
  m <- regmatches(out, regexec(sprintf('"%s": ("[^"]*"|[^,\n]*)', key), out))[[1]]
  if (length(m) < 2) return(NA_character_)
  gsub('^"|"$', "", m[2])
}

answer_for <- function(pid, seed = 1L) {
  p <- all_problems[[pid]]
  e <- problem_expected(p, make_dataset(p, seed))
  v <- e$value
  if (is.list(v) || length(v) > 1) paste(unlist(v), collapse = ",") else as.character(v)
}

test_that("no arguments prints usage and exits 2", {
  local_course()
  res <- run_cli()
  expect_equal(res$status, 2L)
  expect_match(res$out, "Usage")
})

test_that("unknown verb and unknown problem give helpful errors", {
  local_course()
  expect_message(res <- run_cli("frobnicate"), "Unknown command")
  expect_equal(res$status, 2L)
  expect_message(res <- run_cli("show", "t9-nope"), "Unknown problem")
  expect_equal(res$status, 1L)
})

test_that("list shows every problem in teaching order", {
  local_course()
  res <- run_cli("list")
  expect_equal(res$status, 0L)
  pos <- vapply(names(all_problems), function(id) regexpr(id, res$out, fixed = TRUE)[1], 1)
  expect_true(all(pos > 0))
  expect_false(is.unsorted(pos))
})

test_that("show writes the data file and a starter copy, without the answer", {
  dir <- local_course()
  res <- run_cli("show", "t1-gc-content")
  expect_equal(res$status, 0L)
  expect_true(file.exists(file.path(dir, "data", "t1-gc-content.fasta")))
  expect_true(file.exists(file.path(dir, "work", "t1-gc-content.R")))
  expect_match(res$out, "Rscript work/t1-gc-content.R", fixed = TRUE)
  expect_false(grepl(answer_for("t1-gc-content"), res$out, fixed = TRUE))
  # A second show keeps the student's edits.
  writeLines("# mine", file.path(dir, "work", "t1-gc-content.R"))
  run_cli("show", "t1-gc-content")
  expect_equal(readLines(file.path(dir, "work", "t1-gc-content.R")), "# mine")
})

test_that("grade returns JSON and counts attempts; invalid answers don't count", {
  local_course()
  run_cli("show", "t1-gc-content")
  res <- run_cli("grade", "t1-gc-content", "--answer", "banana")
  expect_equal(json_field(res$out, "status"), "invalid")
  expect_equal(json_field(res$out, "attempts"), "0")
  res <- run_cli("grade", "t1-gc-content", "--answer", "0.0001")
  expect_equal(json_field(res$out, "status"), "incorrect")
  expect_equal(json_field(res$out, "attempts"), "1")
  res <- run_cli("grade", "t1-gc-content", "--answer", answer_for("t1-gc-content"))
  expect_equal(json_field(res$out, "status"), "correct")
  expect_equal(json_field(res$out, "attempts"), "2")
})

test_that("grade uses the seed, not the data file", {
  dir <- local_course()
  run_cli("show", "t1-gc-content")
  writeLines(c(">fake", "GGGGGGGGGG"), file.path(dir, "data", "t1-gc-content.fasta"))
  res <- run_cli("grade", "t1-gc-content", "--answer", "1")
  expect_equal(json_field(res$out, "status"), "incorrect")
})

test_that("grade reads long answers from a file", {
  dir <- local_course()
  run_cli("show", "t1-revcomp")
  writeLines(answer_for("t1-revcomp"), file.path(dir, "answer.txt"))
  res <- run_cli("grade", "t1-revcomp", "--answer-file", "answer.txt")
  expect_equal(json_field(res$out, "status"), "correct")
  expect_message(res <- run_cli("grade", "t1-revcomp", "--answer-file", "nope.txt"), "Couldn't read")
  expect_equal(res$status, 1L)
  outside <- withr::local_tempfile(lines = answer_for("t1-revcomp"))
  expect_message(res <- run_cli("grade", "t1-revcomp", "--answer-file", outside), "inside the course folder")
  expect_equal(res$status, 1L)
  expect_message(
    res <- run_cli("grade", "t1-revcomp", "--answer-file", "../x.txt"), "inside the course folder"
  )
  expect_equal(res$status, 1L)
  expect_message(res <- run_cli("grade", "t1-revcomp"), "--answer TEXT")
  expect_equal(res$status, 2L)
})

test_that("hints come one at a time and stop at the last", {
  local_course()
  p <- all_problems[["t1-gc-content"]]
  n <- length(p$hints)
  for (i in seq_len(n)) {
    res <- run_cli("hint", "t1-gc-content")
    expect_match(res$out, sprintf("Hint %d of %d", i, n), fixed = TRUE)
    expect_match(res$out, p$hints[i], fixed = TRUE)
    if (i < n) expect_false(grepl(p$hints[i + 1], res$out, fixed = TRUE))
  }
  res <- run_cli("hint", "t1-gc-content")
  expect_match(res$out, "All .* hints are used")
})

test_that("explain is gated until solved or hints are used and the student asks", {
  local_course()
  explanation <- readLines(file.path(all_problems[["t1-revcomp"]]$folder, "explanation.md"))[1]
  res <- run_cli("explain", "t1-revcomp")
  expect_match(res$out, "Not yet")
  res <- run_cli("explain", "t1-revcomp", "--student-asked")
  expect_match(res$out, "hint\\(s\\) are left")
  for (i in seq_along(all_problems[["t1-revcomp"]]$hints)) run_cli("hint", "t1-revcomp")
  res <- run_cli("explain", "t1-revcomp")
  expect_match(res$out, "Not yet")
  res <- run_cli("explain", "t1-revcomp", "--student-asked")
  expect_match(res$out, explanation, fixed = TRUE)
  expect_match(run_cli("progress")$out, "answer shown")
})

test_that("explain opens after a correct answer", {
  local_course()
  run_cli("grade", "t1-translate", "--answer", answer_for("t1-translate"))
  res <- run_cli("explain", "t1-translate")
  expect_false(grepl("Not yet", res$out))
})

test_that("dataset with a new seed resets that problem and changes the data", {
  dir <- local_course()
  run_cli("show", "t1-gc-content")
  before <- readLines(file.path(dir, "data", "t1-gc-content.fasta"))
  run_cli("hint", "t1-gc-content")
  res <- run_cli("dataset", "t1-gc-content", "--seed", "7")
  expect_match(res$out, "seed 7")
  expect_false(identical(before, readLines(file.path(dir, "data", "t1-gc-content.fasta"))))
  expect_match(run_cli("progress")$out, "hints=0")
  res <- run_cli("grade", "t1-gc-content", "--answer", answer_for("t1-gc-content", 7L))
  expect_equal(json_field(res$out, "status"), "correct")
  expect_message(res <- run_cli("dataset", "t1-gc-content", "--seed", "x"), "whole number")
  expect_equal(res$status, 2L)
})

test_that("progress survives a round trip and a damaged file is set aside", {
  dir <- local_course()
  expect_match(run_cli("progress")$out, "No problems started")
  run_cli("grade", "t1-gc-content", "--answer", "0.1")
  expect_match(run_cli("progress")$out, "t1-gc-content +open +attempts=1")
  path <- file.path(dir, ".compbio-tutor", "progress.dcf")
  writeLines("this is: not\nvalid", path)
  expect_match(run_cli("progress")$out, "No problems started")
  expect_true(file.exists(paste0(path, ".bad")))
})

test_that("tutor.R runs as a script with Rscript", {
  dir <- local_course()
  rscript <- file.path(R.home("bin"), "Rscript")
  out <- system2(rscript, c(shQuote(tutor_script), "list"), stdout = TRUE, stderr = TRUE)
  expect_true(any(grepl("t1-gc-content", out)))
  status <- system2(rscript, c(shQuote(tutor_script), "show", "nope"), stdout = FALSE, stderr = FALSE)
  expect_equal(status, 1L)
})

test_that("paths are confined to the course folder", {
  dir <- local_course()
  expect_true(inside_course("data/x.fasta"))
  expect_true(inside_course(file.path(dir, "work", "a.R")))
  expect_false(inside_course("../elsewhere.txt"))
  expect_false(inside_course("missing/../../elsewhere.txt"))
  expect_true(inside_course("missing/../data/x.fasta"))
  expect_false(inside_course(tempdir()))
  expect_false(inside_course(path.expand("~/.bashrc")))
  expect_error(course_path("..", "x"), "outside the course folder")
  # A symlink inside the folder that points outside doesn't count as inside.
  target <- withr::local_tempdir()
  if (isTRUE(suppressWarnings(file.symlink(target, file.path(dir, "link"))))) {
    expect_false(inside_course(file.path(dir, "link", "answer.txt")))
  }
})

test_that("a whole lesson touches nothing outside the course folder", {
  dir <- local_course()
  home <- withr::local_tempdir("home")
  snapshot <- function(path) {
    files <- list.files(path, recursive = TRUE, all.files = TRUE, full.names = TRUE)
    stats::setNames(as.character(file.mtime(files)), files)
  }
  skill_before <- snapshot(skill_root)
  rscript <- file.path(R.home("bin"), "Rscript")
  run <- function(...) {
    system2(rscript, c(shQuote(tutor_script), ...), stdout = TRUE, stderr = TRUE,
      env = c(sprintf("HOME=%s", home), sprintf("R_USER_CACHE_DIR=%s", home)))
  }
  run("list")
  run("show", "t1-gc-content")
  run("grade", "t1-gc-content", "--answer", "0.5")
  run("hint", "t1-gc-content")
  run("explain", "t1-gc-content")
  run("dataset", "t1-gc-content", "--seed", "3")
  run("progress")
  run("doctor")
  expect_length(list.files(home, all.files = TRUE, no.. = TRUE), 0)
  expect_identical(snapshot(skill_root), skill_before)
  made <- list.files(dir, recursive = TRUE, all.files = TRUE)
  allowed <- "^(\\.compbio-tutor/|data/|work/|\\.Rprofile$)"
  expect_true(all(grepl(allowed, made)), info = paste(made, collapse = ", "))
})

test_that("guide prints the tutor's own guides by name only", {
  local_course()
  res <- run_cli("guide")
  expect_match(res$out, "getting-started")
  res <- run_cli("guide", "getting-started")
  expect_equal(res$status, 0L)
  expect_match(res$out, "# Getting started", fixed = TRUE)
  expect_message(res <- run_cli("guide", "../SKILL"), "Unknown guide")
  expect_equal(res$status, 1L)
})

test_that("grade --from-script explains blanks, a missing answer and outside files", {
  local_course()
  run_cli("show", "r0-variables")
  expect_message(res <- run_cli("grade", "r0-variables", "--from-script", "work/r0-variables.R"), "error")
  expect_equal(res$status, 1L)
  writeLines("x <- 1", "work/r0-variables.R")
  expect_message(
    res <- run_cli("grade", "r0-variables", "--from-script", "work/r0-variables.R"), "answer <- "
  )
  expect_equal(res$status, 1L)
  expect_message(res <- run_cli("grade", "r0-variables", "--from-script", "../x.R"), "inside the course")
  expect_equal(res$status, 2L)
  writeLines("answer <- 0.5", "work/r0-variables.R")
  res <- run_cli("grade", "r0-variables", "--from-script", "work/r0-variables.R")
  expect_match(res$out, '"attempts": 1', fixed = TRUE)
})
