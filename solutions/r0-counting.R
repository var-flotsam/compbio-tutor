seq <- readLines("data/r0-counting.txt")
cat(max(table(strsplit(seq, "")[[1]])), "\n")
