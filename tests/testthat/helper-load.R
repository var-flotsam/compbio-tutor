# Load the tutor's R code (the same files tutor.R sources) into the test env.
repo_root <- normalizePath(file.path(testthat::test_path(), "..", ".."))
skill_root <- file.path(repo_root, "plugin", "skills", "compbio-tutor")
problems_dir <- file.path(skill_root, "problems")
tutor_script <- file.path(skill_root, "scripts", "tutor.R")
for (f in sort(list.files(file.path(skill_root, "scripts", "R"), "\\.R$", full.names = TRUE))) {
  sys.source(f, envir = environment())
}
all_problems <- load_all(problems_dir)

record <- function(problem, seed) {
  text <- make_dataset(problem, seed)
  list(text = text, seq = unname(parse_fasta(text)[[1]]))
}

# Work in a fresh, empty course folder until the calling test ends.
local_course <- function(env = parent.frame()) {
  dir <- withr::local_tempdir("course", .local_envir = env)
  withr::local_dir(dir, .local_envir = env)
  dir
}

# Run the CLI in-process; returns list(status, out) with stdout as one string.
run_cli <- function(...) {
  status <- NA
  out <- utils::capture.output(status <- tutor_main(c(...), problems_dir = problems_dir))
  list(status = status, out = paste(out, collapse = "\n"))
}
