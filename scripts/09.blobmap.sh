#!/bin/bash
#SBATCH --job-name=blobMap
#SBATCH --nodes=1
#SBATCH --mem=48G
#SBATCH --cpus-per-task=12
#SBATCH --time=12:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=dgagler@amnh.org
#SBATCH --output=/logs/slurm-%x_%j.out
#SBATCH --error=/logs/slurm-%x_%j.err

# activate conda env
source ~/.bash_profile
conda activate genome_assembly

# set variables and create dirs
cd "$SLURM_SUBMIT_DIR"
mkdir -p results/minimap2
fastq=/raw_data/ECAP-11_HiFi_merged.fastq.gz
assembly=/results/hifiasm/Elysia_chlorotica.asm.bp.p_ctg.fa
outdir=results/minimap2

# mapping
# -@ 8 means "use 8 threads" 
minimap2 -t ${SLURM_CPUS_PER_TASK} -ax map-hifi ${assembly} \
  ${fastq} | samtools view -@ 8 -b \
  | samtools sort -@ 8 -o ${outdir}/echlr_selfref_aln_sorted.bam

# index BAM 
samtools index ${outdir}/echlr_selfref_aln_sorted.bam
