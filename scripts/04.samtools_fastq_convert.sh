#!/bin/bash
#SBATCH --job-name=fastq_convert
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=4gb
#SBATCH --time=1:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=dgagler@amnh.org
#SBATCH --output=logs/slurm-%x_%j.out
#SBATCH --error=errs/slurm-%x_%j.err

# source and activate conda environment
source /nas4/dgagler/conda/etc/profile.d/conda.sh
conda activate genome_assembly

# set variables and create results dir
cd "$SLURM_SUBMIT_DIR"
samtools fastq raw_data/ECAP-11.hifi_reads.bam > raw_data/ECAP-11_R1_HiFi.fastq
samtools fastq raw_data/ECAP-11_R2.hifi_reads.bam > raw_data/ECAP-11_R2_HiFi.fastq
