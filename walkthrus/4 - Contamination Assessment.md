
# Blobtools
Since Elysia chlorotica is kleptoplastic, we would expect some of our reads to actually be from the chloroplast genome. Let's double check our contamination and see if we can identify some chloroplast reads. 
```
# create dedicated workspace
mkdir genome_cleanup

# create conda env
conda create -n blobtools
conda activate blobtools
# install dependencies
conda install -c anaconda -c bioconda matplotlib docopt tqdm wget pyyaml git pysam

# install blobtools
conda install bioconda -c blobtools
```
We did this in a previous section, but let's reiterate our pre-cleanup assembly stats
```
conda install -c bioconda seqkit
seqkit stats -a Elysia_chlorotica.asm.bp.p_ctg.fa > preclean_assemblyStats.txt
```
Where we see:
- 14,373 contigs with a N50 of 105kb and a total length of 1Gb and. Gross!

### Setting up blobtools
Let's now set blobtools up to screen for microbial contaminants. Running blobtools requires the follow:
- nodes.dmp and names.dmp files from NCBI taxdump
- a .bam file output from minimap2 and samtools (?)
- a .nt blast hit file from ncbi megablast run
Let's prep these files. First, get nodes.dmp and names.dmp files from NCBI taxdump.

```
# activate the blobtools conda env to use blobtools
conda activate blobtools

# create a directory to store data
mkdir setup_data

# download NCBI taxdump and create nodes.dmp and names.dmp
wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz -P setup_data/
tar zxf setup_data/taxdump.tar.gz -C setup_data/ nodes.dmp names.dmp
blobtools nodesdb --nodes setup_data/nodes.dmp --names setup_data/names.dmp
```
Ok, now stuff is getting a bit confusing. I can either go off Yucheol's way of doing things (run your own BLAST) or Rebecca's (use Kraken2 database). I'm confused by Rebecca's workflow so I'll try Yucheol's for now. He took this from Amanda originally lol. The cycle continues.

### Add BLAST hits
BlobTools requires BLAST hits to annotate each read in our assembly. BLASTing an entire genome assembly will take a long ass time, so we can split the assembly up and run it as an array (tech stolen from Amanda). Let's do that:
```
# make directory for split fasta files
mkdir asm_div

# split fasta
awk 'BEGIN {n_seq=0;} /^>/ \
{if(n_seq%50==0){file=sprintf("seq_%d.fa",n_seq);} \
print >> file; n_seq++; next;} { print >> file; }' < Elysia_chlorotica.asm.bp.p_ctg.fa

# move split fastas to asm_div directory
mv seq_* asm_div/

# put split files into a list
cd asm_div/
ls *.fa > blast.list

# check the number of lines in the blast.list file to use as an input to the array command
wc -l blast.list
```
And then run BLASTn, which might take a minute:
```
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
```
### Coverage mapping
In the meantime, blobtools also requires a mapping file i.e. our raw fastq files mapped back to our draft assembly. We'll do this with minimap2 and then convert the resulting SAM file into a BAM using samtools.
```
#!/bin/bash
#SBATCH --job-name=blobMap
#SBATCH --nodes=1
#SBATCH --mem=48G
#SBATCH --cpus-per-task=12
#SBATCH --time=12:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=dgagler@amnh.org
#SBATCH --output=/home/yshin/mendel-nas1/snake_genome_ass/G_ussuriensis_Chromo/scripts/outfiles/slurm-%x_%j.out
#SBATCH --error=/home/yshin/mendel-nas1/snake_genome_ass/G_ussuriensis_Chromo/scripts/outfiles/slurm-%x_%j.err

# activate conda env
source ~/.bash_profile
conda activate genome_assembly

# set variables and create dirs
cd "$SLURM_SUBMIT_DIR"
mkdir -p results/minimap2
fastq=/raw_data/ECAP-11_HiFi_merged.fastq.gz
assembly=/results/hifiasm/Elysia_chlorotica.asm.bp.p_ctg.fa
outdir=results/minimap2/

# mapping
# -@ 8 means "use 8 threads" 
minimap2 -t ${SLURM_CPUS_PER_TASK} -ax map-hifi ${assembly} \
  ${fastq} | samtools view -@ 8 -b \
  | samtools sort -@ 8 -o ${outdir}/echlr_selfref_aln_sorted.bam

# index BAM 
samtools index ${outdir}/echlr_selfref_aln_sorted.bam
```

# Kraken2

