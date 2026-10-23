# Track 0: reading a sequence file
# Fill in the parts marked ___, save the file, then ask the tutor to run it.

lines <- readLines("data/r0-files.fasta")
print(lines)

# 1. Keep the lines that do NOT start with ">".
seq_lines <- lines[___]

# 2. Join them into one string.
seq <- ___

# 3. How many bases?
___
