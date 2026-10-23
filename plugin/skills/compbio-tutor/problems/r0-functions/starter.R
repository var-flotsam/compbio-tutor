# Track 0: functions and loops
# Fill in the parts marked ___, save the file, then ask the tutor to run it.

seqs <- readLines("data/r0-functions.txt")
print(seqs)

# 1. A function that is TRUE when a sequence contains ATG.
has_start <- function(s) {
  ___
}

# 2. Loop over the sequences and count the ones that contain ATG.
count <- 0
for (s in seqs) {
  if (___) {
    count <- count + 1
  }
}
answer <- count
answer
