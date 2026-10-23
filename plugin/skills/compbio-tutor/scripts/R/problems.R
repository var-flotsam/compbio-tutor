# Load and validate problem folders (`problems/<id>/problem.R`).

min_hints <- 3

problem_error <- function(message) {
  stop(structure(
    class = c("problem_error", "error", "condition"),
    list(message = message, call = NULL)
  ))
}

require_field <- function(data, key, check, pid) {
  value <- data[[key]]
  if (is.null(value)) problem_error(sprintf("%s: missing required field '%s'", pid, key))
  if (!check(value)) problem_error(sprintf("%s: field '%s' has the wrong type", pid, key))
  value
}

is_text <- function(x) is.character(x) && length(x) == 1 && nzchar(x)
is_count <- function(x) is.numeric(x) && length(x) == 1

load_problem <- function(folder) {
  path <- file.path(folder, "problem.R")
  env <- new.env(parent = baseenv())
  loaded <- tryCatch(
    {
      sys.source(path, envir = env)
      TRUE
    },
    error = function(err) conditionMessage(err)
  )
  if (!isTRUE(loaded)) problem_error(sprintf("%s: %s", path, loaded))
  data <- env$problem
  if (!is.list(data)) problem_error(sprintf("%s: must define `problem <- list(...)`", path))
  pid <- require_field(data, "id", is_text, basename(folder))
  if (pid != basename(folder)) {
    problem_error(sprintf("%s: id must match folder name '%s'", pid, basename(folder)))
  }
  hints <- require_field(data, "hints", is.character, pid)
  if (length(hints) < min_hints) {
    problem_error(sprintf("%s: needs at least %d hints, has %d", pid, min_hints, length(hints)))
  }
  grader <- require_field(data, "grader", is.list, pid)
  if (!isTRUE(grader$kind %in% names(graders))) {
    problem_error(sprintf(
      "%s: grader$kind must be one of %s", pid, paste(names(graders), collapse = ", ")
    ))
  }
  dataset <- require_field(data, "dataset", is_text, pid)
  answer <- require_field(data, "answer", is_text, pid)
  if (is.null(datasets[[dataset]])) {
    problem_error(sprintf("%s: unknown dataset builder '%s'", pid, dataset))
  }
  if (is.null(answers[[answer]])) {
    problem_error(sprintf("%s: unknown answer function '%s'", pid, answer))
  }
  if (!file.exists(file.path(folder, "explanation.md"))) {
    problem_error(sprintf("%s: explanation.md is missing", pid))
  }
  for (key in c("title", "goal", "background", "prompt", "answer_format")) {
    require_field(data, key, is_text, pid)
  }
  require_field(data, "track", is_count, pid)
  require_field(data, "order", is_count, pid)
  if (is.null(data$starter)) data$starter <- ""
  data$folder <- normalizePath(folder)
  data
}

load_all <- function(root) {
  folders <- list.dirs(root, recursive = FALSE)
  folders <- folders[file.exists(file.path(folders, "problem.R"))]
  problems <- lapply(folders, load_problem)
  keys <- vapply(problems, function(p) p$track * 1000 + p$order, numeric(1))
  problems <- problems[order(keys)]
  stats::setNames(problems, vapply(problems, function(p) p$id, ""))
}

make_dataset <- function(problem, seed) datasets[[problem$dataset]](seed)

problem_expected <- function(problem, data_text) answers[[problem$answer]](data_text)

grade_problem <- function(problem, answer_text, data_text) {
  exp <- problem_expected(problem, data_text)
  options <- problem$grader[names(problem$grader) != "kind"]
  tryCatch(
    do.call(graders[[problem$grader$kind]], c(list(answer_text, exp), options)),
    answer_format_error = function(err) verdict("invalid", "format", conditionMessage(err))
  )
}
