lines <- readLines("data/r0-files.fasta")
answer <- nchar(paste(lines[!startsWith(lines, ">")], collapse = ""))
answer
