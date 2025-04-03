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
