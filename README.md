# eggp_paper_GECCO
Repository with all data, scripts and instructions on how to replicate the eggp paper

## Setup and Install

1. To install `eggp` and `tinyGP`, follow the instructions available at:

- https://github.com/folivetti/srtree/blob/main/apps/eggp/README.md
- https://github.com/folivetti/srtree/blob/main/apps/tinygp/README.md

Compiling from source is recommended to ensure compatibility with the NLOpt library installed in your system.

2. To run `Operon, PySR` and generate the reports, install the Python requirements: 

```bash
python -m venv eggp_experiments
source eggp_experiments/bin/activate
pip install -r requirements.txt
```

## Performance plots and tables

In either `srbench_experiment` or `realworld_experiment` folder, run `python perfplot.py` to generate the performance plots and LaTeX tables. 

## Runtime analysis

First parse the runtime with:

```bash
echo "dataset,algorithm,time" > time.csv
cd srbench_experiment
./parseTime.zsh >> ../time.csv
cd ../realworld_experiment
./parseTime.zsh >> ../time.csv
cd ..
python processTime.py
```

## To rerun the experiments 

To run the experiments, each folder contains an individual bash script for each algorithm and a `runAllOf.sh` script to run all experiments for a single algorithm. The syntax for each script (using `srbench` folder as an example) are:

```bash
./runAllOf.sh [eggp_mo|eggp_so|pysr|operon|tinygp]
./runOperon_srbench.sh <DATASET NAME> <PROCESSOR>
./runPySR_srbench.sh <DATASET NAME> <PROCESSOR>
./runTinyGP_srbench.sh <DATASET NAME>
./runEggp_so_srbench.sh <DATASET NAME>
./runEggp_mo_srbench.sh <DATASET NAME>
```

where `<DATASET NAME>` is the name of the dataset (see `runAllOf.sh` script) and `<PROCESSOR>` is which processor to assign (and enforce single thread mode).
For the `realworld` experiment, the commands are analogous but with an additional argument `<MAX SIZE>` right after `<DATASET NAME>` with the maximum model size: 


```bash
./runAllOf.sh [eggp_mo|eggp_so|pysr|operon|tinygp]
./runOperon_realworld.sh <DATASET NAME> <MAX SIZE> <PROCESSOR>
./runPySR_realworld.sh <DATASET NAME> <MAX SIZE> <PROCESSOR>
./runTinyGP_realworld.sh <DATASET NAME> <MAX SIZE>
./runEggp_so_realworld.sh <DATASET NAME> <MAX SIZE>
./runEggp_mo_realworld.sh <DATASET NAME> <MAX SIZE>
```

To enable multi-threading for `Operon` and `PySR`, just change the `runOperon_*.sh` and `runPySR_*.sh` scripts removing the `taskset -c $3` part of the command line.

## CITING

```bibtex
@inproceedings{eggp,
author = {de Franca, Fabricio Olivetti and Kronberger, Gabriel},
title = {Improving Genetic Programming for Symbolic Regression with Equality Graphs},
year = {2025},
isbn = {9798400714658},
publisher = {Association for Computing Machinery},
address = {New York, NY, USA},
url = {https://doi.org/10.1145/3712256.3726383},
doi = {10.1145/3712256.3726383},
abstract = {The search for symbolic regression models with genetic programming (GP) has a tendency of revisiting expressions in their original or equivalent forms. Repeatedly evaluating equivalent expressions is inefficient, as it does not immediately lead to better solutions.
However, evolutionary algorithms require diversity and should allow the accumulation of inactive building blocks that can play an important role at a later point. 
The equality graph is a data structure capable of compactly storing expressions and their equivalent forms allowing an efficient verification of whether an expression has been visited in any of their stored equivalent forms.
We exploit the e-graph to adapt the subtree operators to reduce the chances of revisiting expressions. Our adaptation, called eggp, stores every visited expression in the e-graph, allowing us to filter out from the available selection of subtrees all the combinations that would create already visited expressions. 
Results show that, for small expressions, this approach improves the performance of a simple GP algorithm to compete with PySR and Operon without increasing computational cost. As a highlight, eggp was capable of reliably delivering short and at the same time accurate models for a selected set of benchmarks from SRBench and a set of real-world datasets.},
booktitle = {Proceedings of the Genetic and Evolutionary Computation Conference},
pages = {},
numpages = {9},
keywords = {Symbolic regression, Genetic programming, Equality saturation, Equality graphs},
location = {Malaga, Spain},
series = {GECCO '25},
archivePrefix = {arXiv},
       eprint = {2501.17848},
 primaryClass = {cs.LG}, 
}
```
