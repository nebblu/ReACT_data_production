#!/bin/bash

#SBATCH --job-name=ds_boost_400k
#SBATCH --constraint=100GbE
##SBATCH --constraint=avx2
#SBATCH --ntasks=1
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=24G
#SBATCH --output="slurm-train_ds_boost_400k.out"


module load anaconda

. /usr/local/anaconda/3.9/etc/profile.d/conda.sh

conda activate cp_env

# If bash is your shell
#
export OMP_NUM_THREADS=$SLURM_JOB_CPUS_PER_NODE

python training_boost_ds.py
