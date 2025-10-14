library(dplyr)
library(bbtcomp)
library(tidyr)
library(cmdstanr)
library(bayesplot)
library(ggplot2)

set_cmdstan_path('~/Projects/cmdstan/')

args <- commandArgs(trailingOnly = TRUE)
criteria <- args[1]
aggfun <- args[2]
if (length(args) > 2) {
  grid <- paste0("_",args[3])
} else {
  grid <- ""
}

fname <- sprintf("perf%s.csv",grid)
my_data <- read.csv(fname)
df <- my_data %>% group_by(dataset, algorithm) %>% summarize( score=case_when(criteria == "R2" & aggfun == "mean" ~ mean(r2_test, na.rm=TRUE), criteria == "R2" & aggfun == "median" ~ median(r2_test, na.rm=TRUE), criteria == "MSE" & aggfun == "mean" ~ mean(-mse_test, na.rm=TRUE), TRUE ~ median(-mse_test, na.rm=TRUE)), .groups='drop') %>% pivot_wider(names_from=algorithm, values_from=score)

numeric_cols <- sapply(df, is.numeric)
df[numeric_cols] <- round(df[numeric_cols], digits = 2)

options(mc.cores = parallel::detectCores(logical = FALSE))
options(bbtcomp.dir = "~/.bbtcomp")
x <- bbtcomp(df)
my_plot <- plot_pwin(x)

fname <- sprintf("plots/ranks/bbt_%s_%s%s_old.eps",criteria, aggfun, grid)
ggsave(my_plot, file=fname, device="eps")
