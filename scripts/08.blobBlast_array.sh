#!/bin/bash
#SBATCH --job-name=blobBlast_array
#SBATCH --nodes=1
#SBATCH --mem=200G
#SBATCH --partition=bigmem
#SBATCH --cpus-per-task=32
#SBATCH --array=1-3
#SBATCH --time=2-00:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=dgagler@amnh.org
#SBATCH --output=logs/slurm-%x_%j.out
#SBATCH --error=logs/slurm-%x_%j.err

# this is run on the AMNH Huxley cluster
# load module
module load BLAST/2.11.0-Linux_x86_64 

# path to genome cleanup directory
wdir=/home/dgagler/nas4/2_HIFI_ASSEMBLY/genome_cleanup

# path to DB
export BLASTDB=/nas3/database/nt_2024_10_23
blastdbcmd -db nt -info

# path to assembly
path_to_asm=${wdir}/asm_div

# output dir
mkdir -p /home/dgagler/nas4/2_HIFI_ASSEMBLY/genome_cleanup/blast_out
out_dir=/home/dgagler/nas4/2_HIFI_ASSEMBLY/genome_cleanup/blast_out

# assign and print array ID
i=${SLURM_ARRAY_TASK_ID}
P=$(awk "NR==$i" ${path_to_asm}/blast.list)

# run blast
blastn \
  -db nt \
  -task megablast \
  -query ${path_to_asm}/${P} \
  -out ${out_dir}/${P}.blast.out \
  -max_target_seqs 10 \
  -max_hsps 1 \
  -evalue 1e-20 \
  -outfmt "6 qseqid staxids bitscore sseqid sskingdoms sscinames" \
  -num_threads=${SLURM_CPUS_PER_TASK}  
