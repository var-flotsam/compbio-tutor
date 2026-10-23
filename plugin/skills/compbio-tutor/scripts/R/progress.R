# Per-student progress, stored as a plain-text DCF file in the course folder.

default_seed <- 1L
progress_fields <- c("seed", "attempts", "hints_used", "solved", "revealed", "last_code")

# $COMPBIO_TUTOR_HOME if set, else `.compbio-tutor` in the current folder.
state_dir <- function() {
  home <- Sys.getenv("COMPBIO_TUTOR_HOME")
  if (nzchar(home)) home else ".compbio-tutor"
}

course_dir <- function() dirname(normalizePath(state_dir(), mustWork = FALSE))

# The student's own copy of a problem's starter code, and their data file.
work_path <- function(pid) file.path(course_dir(), "work", paste0(pid, ".R"))
data_path <- function(pid) file.path(course_dir(), "data", paste0(pid, ".fasta"))

new_problem_progress <- function() {
  list(
    seed = default_seed, attempts = 0L, hints_used = 0L,
    solved = FALSE, revealed = FALSE, last_code = ""
  )
}

load_progress <- function() {
  path <- file.path(state_dir(), "progress.dcf")
  if (!file.exists(path)) return(list())
  rows <- tryCatch(read.dcf(path), error = function(err) NULL)
  ok <- !is.null(rows) && all(c("id", progress_fields) %in% colnames(rows))
  if (!ok) {
    # A damaged file shouldn't block a lesson; keep a copy and start fresh.
    file.rename(path, paste0(path, ".bad"))
    return(list())
  }
  out <- list()
  for (i in seq_len(nrow(rows))) {
    out[[rows[i, "id"]]] <- list(
      seed = as.integer(rows[i, "seed"]),
      attempts = as.integer(rows[i, "attempts"]),
      hints_used = as.integer(rows[i, "hints_used"]),
      solved = as.logical(rows[i, "solved"]),
      revealed = as.logical(rows[i, "revealed"]),
      last_code = sub("^-$", "", unname(rows[i, "last_code"]))
    )
  }
  out
}

save_progress <- function(progress) {
  dir.create(state_dir(), showWarnings = FALSE, recursive = TRUE)
  if (length(progress) == 0) return(invisible())
  rows <- do.call(rbind, lapply(names(progress), function(pid) {
    p <- progress[[pid]]
    values <- vapply(progress_fields, function(f) as.character(p[[f]]), "")
    # DCF can't store an empty value, so an empty code is written as "-".
    values[!nzchar(values)] <- "-"
    c(id = pid, values)
  }))
  tmp <- file.path(state_dir(), "progress.dcf.tmp")
  write.dcf(rows, tmp)
  file.rename(tmp, file.path(state_dir(), "progress.dcf"))
  invisible()
}

get_progress <- function(progress, pid) {
  if (is.null(progress[[pid]])) new_problem_progress() else progress[[pid]]
}
