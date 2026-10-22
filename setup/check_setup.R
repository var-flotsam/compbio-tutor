# compbio-tutor setup check
#
#   Rscript setup/check_setup.R            report what is missing
#   Rscript setup/check_setup.R --install  also install missing packages
#
# Students and teachers run this once before the first lesson.

min_r <- "4.3.0"
# Packages each track needs. Biostrings comes from Bioconductor; the rest from CRAN.
needed <- list(
  "Track 1" = c("Biostrings")
)

args <- commandArgs(trailingOnly = TRUE)
install <- "--install" %in% args
ok <- TRUE

cat("compbio-tutor setup check\n\n")

r_version <- paste(R.version$major, R.version$minor, sep = ".")
if (package_version(r_version) < package_version(min_r)) {
  cat(sprintf("[!] R %s is installed, but the lessons need R %s or newer.\n", r_version, min_r))
  cat("    Download a newer R from https://cran.r-project.org/\n")
  ok <- FALSE
} else {
  cat(sprintf("[ok] R %s\n", r_version))
}

bioc <- c("Biostrings")
for (track in names(needed)) {
  for (pkg in needed[[track]]) {
    if (requireNamespace(pkg, quietly = TRUE)) {
      cat(sprintf("[ok] %s (%s)\n", pkg, track))
      next
    }
    if (!install) {
      cat(sprintf("[!] %s is missing (needed for %s).\n", pkg, track))
      ok <- FALSE
      next
    }
    cat(sprintf("Installing %s...\n", pkg))
    repos <- "https://cloud.r-project.org"
    if (pkg %in% bioc) {
      if (!requireNamespace("BiocManager", quietly = TRUE)) {
        install.packages("BiocManager", repos = repos)
      }
      BiocManager::install(pkg, update = FALSE, ask = FALSE)
    } else {
      install.packages(pkg, repos = repos)
    }
    if (requireNamespace(pkg, quietly = TRUE)) {
      cat(sprintf("[ok] %s installed\n", pkg))
    } else {
      cat(sprintf("[!] %s did not install. Copy the messages above for your teacher.\n", pkg))
      ok <- FALSE
    }
  }
}

if (ok) {
  cat("\nAll set. Open Claude Code in this folder and ask to start a compbio lesson.\n")
} else {
  cat("\nSomething is missing. Run again with --install, or ask your teacher.\n")
  quit(status = 1)
}
