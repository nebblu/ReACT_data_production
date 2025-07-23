#!/bin/bash

#SBATCH --job-name=produce_react_spectra
##SBATCH --constraint=4TBdatadisk
#SBATCH --ntasks=40
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=1
##SBATCH --mem-per-cpu=1G
#SBATCH --output="err_out/output-bacon_data.log"
#SBATCH --error="err_out/error-bacon_data.log"


module load anaconda

. /usr/local/anaconda/3.9/etc/profile.d/conda.sh

conda activate react

##Modules
#module load gcc/12.1.0


## ReACT paths
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/bbose/sundials/instdir/lib:/home/bbose/ACTio-ReACTio/reactions/lib:${LD_LIBRARY_PATH}


# Custom temp dir
export TMPDIR=$HOME/tmp_parallel
mkdir -p "$TMPDIR"

# Parallel setup
srun="srun --exclusive -N1 -n1"
parallel="parallel --compress --tmpdir $TMPDIR --delay 0.2 -j ${SLURM_NTASKS}"

echo "Slurm tasks: ${SLURM_NTASKS}"

cd pipe_cosmopower_parallel

## We iterate over first index which is the process number (1 to ntasks)
## Second index gives the total number of processes = ntasks
## Third index is the total number of cosmologies you want to run
## Fourth index is the starting cosmology
## NOTE: 3rd+4th index should not exceed total number of cosmologies in data/cosmo.txt, i.e. the total cosmologies in the param file

# Run 4
total_cosmos=100000
start_cosmo=300000

# # Run 3
# total_cosmos=100000
# start_cosmo=200000

# # Run 1
# total_cosmos=100000
# start_cosmo=100000

# # Run 1
# total_cosmos=100000
# start_cosmo=1


# Test run 
#total_cosmos=40000
#start_cosmo=1

# Dark Scattering 
$parallel "$srun ./run_cp_ds_err.sh {1} ${SLURM_NTASKS} ${total_cosmos} ${start_cosmo}" ::: $(seq 1 ${SLURM_NTASKS})

# f(R)
#$parallel "$srun ./run_cp_fr.sh {1} ${SLURM_NTASKS} ${total_cosmos} ${start_cosmo}" ::: $(seq 1 ${SLURM_NTASKS})

