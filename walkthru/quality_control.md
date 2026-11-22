## Quality control and data sanity check
This PacBio HiFi data was generated using a Pacbio Revio II. It was delivered as 2 separate sequencing runs for a total of ~40Gb of data. The data were delivered in bam format, which is not compatible with hifiasm as I have it installed. As such, we first convert the files to fastq format using samtools.
```
samtools fastq input.bam > output.fastq
```
We now have 2 fastq files from 2 sequencing runs and we can generate basic sequencing summary stats using seqkits.
```
seqkit stats ECAP-11_R1_HiFi.fastq.gz
seqkit stats ECAP-11_R2_HiFi.fastq.gz
```
The first file has 2.8 million sequences with a N50 of 8395bp and the second has 422k sequences with an N50 of 9089. Not ideal N50s. The average quality scores are 28 in both cases, which is alright.
![[Screenshot 2026-11-12 at 8.25.50 AM.png]]
Let's now do a basic estimate of sequencing depth based on the # of bp in our fastq files divided by the estimated genome size. We know the # of bps in each fastq file from seqkit stats: 25.429Gb and 3.832Gb. The current draft genome of Elysia chlorotica is 0.56Gb.

So 25.429/0.56Gb and 3.832/0.56Gb = 45.4x and 6.8x, for a total of 52.2x average coverage. This is fine.

I then ran fastqc on them to get overall quality assessments. The sequence quality is pretty good, hanging around 38 Q-score
![[fastqc_example.png]]

Now let's do a sanity check. Let's take the first read in the first fastq file and BLAST it. We immediately get...questionable results. Top hits are all coronaviruses, but the query cover is very low. So these reads are barely aligning to anything, so they are probably nonsense reads, possibly errors from PCR. There are several Elysia genomes out there so we would expect to be hitting those.![[Screenshot 2026-11-12 at 8.28.56 AM.png]]
Ok. Let's try the second read anddd same thing. Now we'll try the last read in the first fastq. Yep, nothing. I also randomly subsampled 10 sequences and blasted them and all the same. Best we have are an aplysia and physella sequence hit here and there
![[Screenshot 2026-11-12 at 8.32.27 AM.png]]
Let's try the 2nd fastq. Same thing. Ok, well that sucks.

It's time for a more systematic analysis of the contamination. To start, let's try mapping our fastq reads to the existing Elysia chlorotica draft genome (found here: https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_003991915.1/). 

For downstream simplicity, let's first merge these fastq files together.
```
cat ECAP-11_R1_HiFi.fastq.gz ECAP-11_R2_HiFi.fastq.gz > ECAP-11_HiFi_merged.fastq.gz
```
Now we can run minimap2 using the PacBio settings, which uses homopolymer-compressed (HPC) minimizers as seeds and is improves sensitivity when aligning PacBio CLR reads.
```
minimap2 -ax map-pb 2019_referenceGenome/GCA_003991915.1/GCA_003991915.1_ElyChl2.0_genomic.fna raw_data/ECAP-11_HiFi_merged.fastq.gz > results/minimap2/Echlr_ECAP-11_2019Draft.aln.sam
```

