data = read.csv('./results.csv', header=T)
png("./chart.png")
plot(data$versions, data$copies, type="l", col="red", main="Database Growth",
     xlab="Versions saved", ylab="Size on disk")
lines(data$versions, data$diffs, type="l", col="orange")
lines(data$versions, data$tokendiffs, type="l", col="blue")
legend("topleft", c("Copies", "Diffs", "Token Diffs"), col=c("red", "orange",
                                                            "blue"), pch=22)
dev.off()
