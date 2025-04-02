# eggp_paper_GECCO
Repository with all data, scripts and instructions on how to replicate the eggp paper

## Setup and Install

1. Follow up the instructions in:

- https://github.com/folivetti/srtree/blob/main/apps/eggp/README.md
- https://github.com/folivetti/srtree/blob/main/apps/tinygp/README.md

2. Install Python requirements: 

```bash
python -m venv eggp_experiments
source eggp_experiments/bin/activate
pip install -r requirements.txt
```

## PySR

./runPySR_srbench.sh <dataset-name> <processor>
./runPySR_srbench_all.sh
