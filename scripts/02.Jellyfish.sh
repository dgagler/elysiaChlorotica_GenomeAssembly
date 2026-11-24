#!/bin/bash
#SBATCH --job-name=jellyfish
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32gb
#SBATCH --time=2:00:00
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
mkdir -p results

# run jellyfish
zcat raw_data/ECAP-11_HiFi_merged.fastq.gz | awk 'NR%4==1{print ">"substr($0,2)} NR%4==2{print}' | jellyfish count -m 31 -s 3G -t ${SLURM_CPUS_PER_TASK} -C /dev/fd/0 -o results/${name}_31kmer.jf

# k-mer histogram
jellyfish histo -t ${SLURM_CPUS_PER_TASK} results/${name}_31kmer.jf > results/${name}_31kmer_counts.histo
