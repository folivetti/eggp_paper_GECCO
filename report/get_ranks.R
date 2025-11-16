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

fname <- "perf_pivoted.csv"
my_data <- read.csv(fname)

options(mc.cores = parallel::detectCores(logical = FALSE))
options(bbtcomp.dir = "~/.bbtcomp")

x <- bbtcomp(my_data,lrope=T, paired=F)
my_plot <- plot_pwin(x,control='eggp') +
  theme_minimal(base_size = 20)

fname <- sprintf("plots/ranks/bbt_%s_%s_rope.eps",criteria, aggfun)
ggsave(my_plot, file=fname, device="eps", width = 15, height = 5)
