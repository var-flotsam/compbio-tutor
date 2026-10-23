counts <- scan("data/r0-variables.txt", quiet = TRUE)
answer <- round(counts[3] / sum(counts), 4)
answer
