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

fname <- sprintf("perf%s_pivoted.csv",grid)
my_data <- read.csv(fname)

options(mc.cores = parallel::detectCores(logical = FALSE))
options(bbtcomp.dir = "~/.bbtcomp")

x <- bbtcomp(my_data)
my_plot <- plot_pwin(x)

fname <- sprintf("plots/ranks/bbt_%s_%s%s.eps",criteria, aggfun, grid)
ggsave(my_plot, file=fname, device="eps")

x <- bbtcomp(my_data,lrope=T, paired=F)
my_plot <- plot_pwin(x)

fname <- sprintf("plots/ranks/bbt_%s_%s%s_rope.eps",criteria, aggfun, grid)
ggsave(my_plot, file=fname, device="eps")
