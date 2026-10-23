seq <- readLines("data/r0-counting.txt")
answer <- max(table(strsplit(seq, "")[[1]]))
answer
