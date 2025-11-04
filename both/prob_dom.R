library(dplyr)
library(bbtcomp)
library(tidyr)
library(cmdstanr)
library(bayesplot)
library(ggplot2)

set_cmdstan_path('~/Projects/cmdstan/')


options(mc.cores = parallel::detectCores(logical = FALSE))
options(bbtcomp.dir = "~/.bbtcomp")

my_data <- read.csv("best_rates.csv")
x <- bbtcomp(my_data,lrope=T, paired=F)
my_plot <- plot_pwin(x,control='eggp')

fname <- "plots/ranks/bbt_best_rates.eps"
ggsave(my_plot, file=fname, device="eps")

my_data <- read.csv("dominance_rates.csv")
x <- bbtcomp(my_data,lrope=T, paired=F)
my_plot <- plot_pwin(x, control="eggp")

fname <- "plots/ranks/bbt_dominance_rates.eps"
ggsave(my_plot, file=fname, device="eps")
