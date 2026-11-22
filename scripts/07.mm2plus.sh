#!/bin/bash
#SBATCH --job-name=mm2plus
#SBATCH --nodes=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=24gb
#SBATCH --time=09:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=dgagler@amnh.org 
#SBATCH --output=logs/slurm-%x_%j.out
#SBATCH --error=errs/slurm-%x_%j.err

# source and activate conda environment
source /nas4/dgagler/conda/etc/profile.d/conda.sh
conda activate genome_assembly

# set variables and create results dir
cd "$SLURM_SUBMIT_DIR"
mkdir -p results/minimap2

# align using pac-bio default settings
minimap2 -ax asm5 2019_referenceGenome/GCA_003991915.1/GCA_003991915.1_ElyChl2.0_genomic.fna results/hifiasm/Elysia_chlorotica.asm.bp.p_ctg.gfa > results/minimap2/Echlr_ECAP-11_2019Draft_AssemblyAlignment.aln.sam

