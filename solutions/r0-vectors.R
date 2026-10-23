lengths <- scan("data/r0-vectors.txt", quiet = TRUE)
cat(sum(lengths > 1000), "\n")
