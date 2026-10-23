# Run each reference solution the way the tutor checks a student's work: copy it
# to work/<id>.R and grade it with --from-script, which sources it in a fresh R.
solutions_dir <- file.path(repo_root, "solutions")

test_that("every problem has a reference solution", {
  for (id in names(all_problems)) {
    expect_true(file.exists(file.path(solutions_dir, paste0(id, ".R"))), info = id)
  }
})

test_that("reference solutions are graded correct from the script on several seeds", {
  skip_if_not_installed("Biostrings")
  for (p in all_problems) {
    for (seed in c(1L, 2L, 3L, 11L)) {
      local_course()
      run_cli("dataset", p$id, "--seed", seed)
      dir.create("work", showWarnings = FALSE)
      file.copy(file.path(solutions_dir, paste0(p$id, ".R")), file.path("work", paste0(p$id, ".R")))
      res <- run_cli("grade", p$id, "--from-script", file.path("work", paste0(p$id, ".R")))
      info <- sprintf("%s seed %d: %s", p$id, seed, res$out)
      expect_match(res$out, '"status": "correct"', fixed = TRUE, info = info)
    }
  }
})

test_that("every starter ends by setting answer, so it can be graded from the script", {
  for (p in all_problems) {
    starter <- readLines(file.path(p$folder, p$starter))
    expect_true(any(grepl("^answer <- ", starter)), info = p$id)
  }
})
