#!/usr/bin/env Rscript
# compbio-tutor command line: the only interface Claude uses during a lesson.
#
#   Rscript tutor.R doctor [--install-packages]
#   Rscript tutor.R list
#   Rscript tutor.R show <problem-id>
#   Rscript tutor.R dataset <problem-id> [--seed N]
#   Rscript tutor.R grade <problem-id> --from-script work/<problem-id>.R
#   Rscript tutor.R grade <problem-id> --answer TEXT   (or --answer-file PATH)
#   Rscript tutor.R hint <problem-id>
#   Rscript tutor.R explain <problem-id> [--student-asked]
#   Rscript tutor.R progress
#
# Base R only: it runs as soon as R is installed, before any package is.

local({
  file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  script_dir <- dirname(normalizePath(sub("^--file=", "", file_arg[1])))
  for (f in sort(list.files(file.path(script_dir, "R"), "\\.R$", full.names = TRUE))) {
    sys.source(f, envir = globalenv())
  }
  status <- tutor_main(
    commandArgs(trailingOnly = TRUE),
    problems_dir = file.path(dirname(script_dir), "problems")
  )
  quit(save = "no", status = status)
})
