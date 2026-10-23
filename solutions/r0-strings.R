seq <- readLines("data/r0-strings.txt")
cat(toupper(substr(seq, 5, 14)), "\n")
