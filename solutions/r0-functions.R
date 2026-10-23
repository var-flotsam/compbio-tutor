seqs <- readLines("data/r0-functions.txt")
has_start <- function(s) grepl("ATG", s, fixed = TRUE)
count <- 0
for (s in seqs) if (has_start(s)) count <- count + 1
answer <- count
answer
