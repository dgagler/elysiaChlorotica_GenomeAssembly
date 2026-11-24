#!/bin/bash
#SBATCH --job-name=kraken2
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=48gb
#SBATCH --time=8:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=dgagler@amnh.org 
#SBATCH --output=logs/slurm-%x_%j.out
#SBATCH --error=errs/slurm-%x_%j.err

# source and activate conda environment
source /nas4/dgagler/conda/etc/profile.d/conda.sh
conda activate genome_assembly

# set variables and create results dir
cd "$SLURM_SUBMIT_DIR"
name="ECAP-11_HiFi_merged"
mkdir -p results/kraken2
db="path/to/db/"
reads="raw_data/ECAP-11_HiFi_Merged.fastq.gz"

# run it
kraken2 \
  --db ${db} \
  --threads "${SLURM_CPUS_PER_TASK}" \
  --confidence 0.1 \
  --minimum-hit-groups 2 \
  --report "results/kraken2/${name}_kraken2.report" \
  --output "results/kraken2/${name}_kraken2.output" \
  --classified-out "results/kraken2/${name}_classified.fastq" \
  --unclassified-out "results/kraken2/${name}_unclassified.fastq" \
  "${reads}"

