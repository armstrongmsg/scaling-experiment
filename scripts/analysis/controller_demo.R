factor_p <- 0.2
factor_d <- 1

x <- seq(-1, 1, by = 1/16)
erro <- cbind(sin(pi*x))

df <- data.frame(time=x,erro=erro)
diff_err <- sapply(2:length(x), function(x) df$erro[x] - df$erro[x-1])
diff_err[length(x)] <- 0
df <- data.frame(time=x,erro=erro,diff_err=diff_err)
df$prop <- -factor_p*df$erro
df$deriv <- -(factor_p*df$erro + factor_d*df$diff_err)
df$diff_err <- -df$diff_err

df2 <-melt(df, id = c("time"))

ggplot(df2, aes(x = time, y = value, colour = variable)) + 
    geom_line() +
    facet_grid(. ~ variable)
