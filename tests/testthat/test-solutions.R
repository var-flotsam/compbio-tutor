# Run each reference solution with Rscript, as a student would, and grade it.
solutions_dir <- file.path(repo_root, "solutions")
rscript <- file.path(R.home("bin"), "Rscript")

test_that("every problem has a reference solution", {
  for (id in names(all_problems)) {
    expect_true(file.exists(file.path(solutions_dir, paste0(id, ".R"))), info = id)
  }
})

test_that("reference solutions are graded correct on several seeds", {
  skip_if_not_installed("Biostrings")
  for (p in all_problems) {
    for (seed in c(1L, 2L, 3L, 11L)) {
      dir <- withr::local_tempdir()
      dir.create(file.path(dir, "data"))
      data <- make_dataset(p, seed)
      writeLines(data, file.path(dir, "data", paste0(p$id, ".fasta")), sep = "")
      out <- withr::with_dir(dir, system2(
        rscript, shQuote(file.path(solutions_dir, paste0(p$id, ".R"))),
        stdout = TRUE, stderr = FALSE
      ))
      v <- grade_problem(p, paste(out, collapse = "\n"), data)
      expect_equal(v$status, "correct", info = sprintf("%s seed %d: %s", p$id, seed, v$message))
    }
  }
})
