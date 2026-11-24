Let's now estimate k-mers, genome size, heterozygosity to see how tricky this genome really will be.
# Jellyfish
We start by running jellyfish, which counts k-mers quite efficiently. We'll run it standard using k = 21 for k-mer size. Here's a slurm script:
```
#!/bin/bash
#SBATCH --job-name=jellyfish
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16gb
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
name="ECAP-11_R1_HiFi"
mkdir -p results

# run jellyfish
zcat raw_data/*fastq.gz | awk 'NR%4==1{print ">"substr($0,2)} NR%4==2{print}' | jellyfish count -m 21 -s 3G -t ${SLURM_CPUS_PER_TASK} -C /dev/fd/0 -o results/${name}_kmer.jf

# k-mer histogram
jellyfish histo -t ${SLURM_CPUS_PER_TASK} results/${name}_kmer.jf > results/${name}_kmer_counts.histo
```

This will output a .histo file which can then be sent over to the GenomeScope2 website ([http://genomescope.org/genomescope2.0/](http://genomescope.org/genomescope2.0/)) for a quick summary.
# GenomeScope2
We can see the following estimations:
- Genome size = 0.5Gb (the draft assembly is 0.56Gb)
- Disturbingly highly heterozygosity (4.7%)
- About 45% repeat content
- 24x coverage (but probably closer to 50, see below)
- We only have a single peak, which can happen in genomes with high heterozygosity (which we obviously have). This is because we have many k-mers being identified as heterozygous components of the haploid genome instead of as the diploid counterpart. This might explain the low coverage, as a second peak would double us up to about 48x, which would be more tolerable. 
![[GenomeScope_kmer21_LinearModel.png]]

![[GenomeScope_kmer21_Summary.png]]

Overall, this looks ok, but we can try running jellyfish with k-mer count set to 31 to see how that changes things.

The next steps will be to assemble the genome using hifiasm (and confirm that we have very clear haplotype separation of primary and alternative contigs) and to run BUSCO to see if we see widespread gene duplications (see this discussion for more details of what we expect in a case of high heterozygosity like here: https://github.com/schatzlab/genomescope/issues/144)