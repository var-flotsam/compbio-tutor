lines <- readLines("data/r0-files.fasta")
cat(nchar(paste(lines[!startsWith(lines, ">")], collapse = "")), "\n")
