# eggp_papers

Repository with all data, scripts and instructions on how to replicate the papers benchmarking `eggp`.

## Setup and Install

Most algorithms are installed via pip, some of them require additional steps:

1. [Optional] Create a new environment:

```bash
python -m venv eggp_experiments
source eggp_experiments/bin/activate
```

2. Install the requirements and part of the algorithms:

```bash
pip install -r requirements.txt
```

3. Install GOMEA:

- Install the following requirements: make, cmake, eigen, python-devtools, pybind11
- Clone the repository and install:

```bash
git clone https://github.com/marcovirgolin/gpg
cd gpg
make
```

4. Install GPZGD:

- get the fixed gpzgd code from [https://github.com/cavalab/srbench/tree/master/algorithms/gpzgd](https://github.com/cavalab/srbench/tree/master/algorithms/gpzgd)
- run:

```bash
cd gpzgd
make
sudo cp dist/regressor /usr/local/bin/gpzgd_regressor
```

6. NeoGP

TBD

## Running the experiments 

The experiments folder contains an individual bash script for each algorithm and a `runAllOfRW.sh` and `runAllOfSRBench.sh` scripts to run all experiments for a single algorithm for that particular benchmark. **Note that the results may differ slightly from the paper since we are not fixing the random seed AND some of the algorithms may have been updated in the meantime.**

The syntax for each script are:

```bash
./runAllOfRW.sh <NAME>
./runAllOfSRBench.sh <NAME>
./run<ALGORITHM>_srbench.sh <DATASET NAME> <PROCESSOR>
./run<ALGORITHM>_srbench.sh <DATASET NAME> <PROCESSOR> srbench
```

where 

`<NAME>` is one of `operon,pysr,eggp,pysips,symregg,random,qlattice,gomea,gpzdg,neogp,rf,gsgp`
`<ALGORITHM>` is one of the algorithm names (see `experiments` folder)
`<DATASET NAME>` is the dataset name (see datasets folder)
`<PROCESSOR>` is a processor number to assign, only valid for PySR which sometimes misbehaves with multithread
A last argument called "srbench" should be passed to run the experiments for SRBench.

The results will be stored in the folder `report/results`.

**WARNING:** after running experiments with PySIPS, run `fix_pysips.py` script in the `report` folder to fix the size values of the generated expressions.

## Plots and Tables

In the folder `report`, you should first generate the tabulated results with the command:

```bash
python gen_dataframe.py --thr 1.0 --size 50  
```

The argument `thr` is the threshold for picking from the Pareto front. A value of 1.0 means it will peek the most accurate model w.r.t. the training set. A value of $p < 1.0$ means that it will peek the smallest model within $p\%$ of the best MSE.
The argument`size` removes any expression with size larger than that value.

To obtain the LaTeX table of the MSE values, model sizes, and ranks, run:

```bash
python gen_acc_tables.py <METRIC> <AGG>
```

where `<METRIC>`  can be R2 or MSE, and `<AGG>` can be mean, median, min.

```bash
python gen_ranks.py <METRIC> <AGG>
```

where `<METRIC>` can be R2, MSE, or size, and `<AGG>` can be mean, median, min, max.

To generate the boxplots run:

```bash
python gen_boxplots.py
```

To generate the ELO score plot run:

```bash
python gen_elo.py <METRIC> <AGG>
```

where `<METRIC>` can be R2, MSE, and `<AGG>` can be mean, median, min, max.


To run the dominance analysis w.r.t. PySIPS, first run:

```bash
python gen_dominance.py --n <ITER>
```

where `<ITER>` is the iteration numbers of the bootstrapping (10000 in the paper).
Then run:

```bash
python gen_perc_dominance.py 
```
which will display the LaTeX table.

To create the BBT plot, first run:

```bash
python pivot.py <METRIC>
```

where `<METRIC>` is either MSE or R2, open the file `perf_pivoted.csv` and replace any `inf` with a very large value.
Then run:

```bash
Rscript get_ranks.R <METRIC> <AGG>
```
where `<METRIC>` can be R2, MSE, and `<AGG>` can be mean, median, min, max.

## Runtime analysis

First parse the runtime with:

```bash
echo "dataset,algorithm,time" > time.csv
./parseTime.zsh >> time.csv
python processTime.py
```


## CITING

```bibtex

```
