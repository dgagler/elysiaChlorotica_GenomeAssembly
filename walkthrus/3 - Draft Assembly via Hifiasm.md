We now try to assemble the genome using hifiasm, which is a ubiquitous tool for assembling PacBio HiFi Data. It is quick, easy to use, and haplotype-resolved. Our genome is relatively small, so it wouldn't take too long to run on a HPC:
```
#!/bin/bash
#SBATCH --job-name=echlr_hifiasm
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=48gb
#SBATCH --time=10:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=dgagler@amnh.org
#SBATCH --output=logs/slurm-%x_%j.out
#SBATCH --error=errs/slurm-%x_%j.err

# source and activate conda environment
source /nas4/dgagler/conda/etc/profile.d/conda.sh
conda activate genome_assembly

# set variables and create results dir
cd "$SLURM_SUBMIT_DIR"
name="Elysia_chlorotica"
mkdir -p results

# run hifiasm
hifiasm -o results/${name}.asm -t 16 raw_data/ECAP-11_R1_HiFi.fastq raw_data/ECAP-11_R2_HiFi.fastq
```

This produces the following set of outputs (excluding the .fa file which I manually created lol I'm writing this retrospectively sorry):
![[hifiasm_outputs.png]]

Most notably, we have our "bp.p_ctg.gfa" file which is our assembly graph of primary contigs. We should also take a peek at our "hap1.p_ctg.gfa" and "hap2.p_ctg.gfa" files which contain our phased haplotypes (which will give a sense for the size of the alternate assemblies, which which will confirm we indeed have a diploid genome and give a sense for the size of the alternate assemblies estimated via our minimap2 alignment in section 1.

We can do this by first getting summary stats from our assemblies using **seqkit**. Before we do that, however, we must convert our graphical .gfa files into plain-old fasta files (.fa)

```
awk '/^S/{print ">"$2"\n"$3}' Elysia_chlorotica.asm.bp.p_ctg.gfa > Elysia_chlorotica.asm.bp.p_ctg.fa

awk '/^S/{print ">"$2"\n"$3}' Elysia_chlorotica.asm.bp.hap1.p_ctg.gfa > Elysia_chlorotica.asm.bp.hap1.p_ctg.fa

awk '/^S/{print ">"$2"\n"$3}' Elysia_chlorotica.asm.bp.hap2.p_ctg.gfa > Elysia_chlorotica.asm.bp.hap2.p_ctg.fa
```
We can then run seqkit to get summary stats:
```
seqkit stats -a Elysia_chlorotica.asm.bp.p_ctg.fa > assembly_stats/Elysia_chlorotica.asm.bp.p_ctg_summaryStats.txt

seqkit stats -a Elysia_chlorotica.asm.bp.hap1.p_ctg.fa > assembly_stats/Elysia_chlorotica.asm.bp.hap1.p_ctg_summaryStats.txt

seqkit stats -a Elysia_chlorotica.asm.bp.hap2.p_ctg.fa > assembly_stats/Elysia_chlorotica.asm.bp.hap2.p_ctg_summaryStats.txt
```

Wherein we see that our primary assembly is quite disappointing: **14,373 contigs and a contig N50 of 105kb.** This is **extremely** low, as we would expect around ~1Mb at a minimum. This assembly is fragmentary as shit!
![[hifiasm_primary_assembly_seqkit.png]]

Our phased haplotypes, however, show us that something might be amiss! The size differences between our hap1 and hap2 assemblies are quite different. The hap1 is about 0.9Mb and hap2 is about 0.5Mb
![[hifiasm_phased_summarystats.png]]

Let's stop to think about what all this means...our assembly is highly fragmentary and we have unbalanced haplotypes. As per the hifiasm docs, we could try setting smaller value for `-s` (default: 0.55) or turning  on`--hom-cov`. We could try raising -D or -N to improve the resoltuion of repetitive regions. We could also set a higher value for --purge-max which will make the primary assembly more contiguous but will collapse repeats or segmental duplications.

**Tuned parameter run:**
```
# run hifiasm
hifiasm -o results/${name}.asm -t ${SLURM_CPUS_PER_TASK} -s 0.3 raw_data/ECAP-11_HiFi_merged.fastq.gz
```

Looking at our log file, we can see via [M::purge_dups] that our inferred homozygous read coverage threshold is 41x. Our 
GenomeScope2 estimate is 48x (assuming we understand that the value of 24x reported is only half of the true value since it missed the heterozygous peak--other line of evidence for this is that our manual estimate of coverage estimated ~50x). As such, we focus on s which adjusts the threshold for purging duplicate haplotigs. The default is 0.55, and we'll try 0.3 here

This yields a new genome assembly, but it's not much better than before. The new stats:
- 13612 contigs with an N50 of 108kb

