## Basic statistics
The data was delivered as 2 separate sequencing runs. It's not clear to me why. Regardless, they were delivered in bam format but this is not compatible with hifiasm, so I've converted the files to fastq format using samtools.
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
Let's now do an estimate of sequencing depth based on the # of bp in our fastq files divided by the estimated genome size. We know the # of bps in each fastq file from seqkit stats: 25.429Gb and 3.832Gb. The current draft genome of Elysia chlorotica is 0.56Gb.

So 25.429/0.56Gb and 3.832/0.56Gb = 45.4x and 6.8x, **f**or a total of **52.2x average coverage**.** This is fine.
## FastQC
Let's now check the sequence quality using fastQC.
```
fastqc ECAP-11_R1_HiFi.fastq.gz ECAP-11_R2_HiFi.fastq.gz
```
The sequence quality is pretty good, hanging around 38 Q-score
![[fastqc_example.png]]
Now let's look at the fastq files for a sanity check. Let's take the first read in the first fastq file and BLAST it. ANd we get...questionable results. Top hits are all coronaviruses, but the query cover is very low. So these reads are barely aligning to anything, so they are probably nonsense reads, possibly errors from PCR. There are several Elysia genomes out there so we would expect to be hitting those.![[Screenshot 2026-11-12 at 8.28.56 AM.png]]
Ok. Let's try randomly sampling some sequences and doing the same.
```
seqtk sample -s77 ECAP-11_R1_HiFi.fastq.gz 10 > ECAP-11_R1_HiFi_Subsample.fastq.gz
```
All 10 of the random sequences were the same and I saw the same thing in the 2nd fastq file. There are lots of sequences here, though, so let's do a more systematic analysis. We can do this by trying to map our reads against a known reference. In this case, the existing draft genome assembly of Elysia chlorotica (found here: [https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_003991915.1/](https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_003991915.1/)). We'll be using **Minimap2** to that end.
## minimap2
We will now use minimap2 to map our fastq files to a reference genome. In this case, we'll be mapping them to the existing Elysia chlorotica draft assembly. For downstream simplicity, let's first merge these fastq files together.
```
cat ECAP-11_R1_HiFi.fastq.gz ECAP-11_R2_HiFi.fastq.gz > ECAP-11_HiFi_merged.fastq.gz
```
Now we can run minimap2 using the PacBio settings, which uses homopolymer-compressed (HPC) minimizers as seeds and is improves sensitivity when aligning PacBio CLR reads.
``` 
minimap2 -ax map-pb 2019_referenceGenome/GCA_003991915.1/GCA_003991915.1_ElyChl2.0_genomic.fna raw_data/ECAP-11_HiFi_merged.fastq.gz > results/minimap2/Echlr_ECAP-11_2019Draft.aln.sam
```
Check out the summary stats of the alignment using flagstat:
```
samtools flagstat Echlr_ECAP-11_2019Draft_Minimap2.aln.sam > qc/flagstat/Echlr_ECAP-11_2019Draft_Minimap2.flagstat.txt

cat qc/flagstat/Echlr_ECAP-11_2019Draft_Minimap2.flagstat.txt
8124052 + 0 in total (QC-passed reads + QC-failed reads)
3268155 + 0 primary
2418649 + 0 secondary
2437248 + 0 supplementary
0 + 0 duplicates
0 + 0 primary duplicates
7731904 + 0 mapped (95.17% : N/A)
2876007 + 0 primary mapped (88.00% : N/A)
0 + 0 paired in sequencing
0 + 0 read1
0 + 0 read2
0 + 0 properly paired (N/A : N/A)
0 + 0 with itself and mate mapped
0 + 0 singletons (N/A : N/A)
0 + 0 with mate mapped to a different chr
0 + 0 with mate mapped to a different chr (mapQ>=5)
```
We note that only about 35% of our reads mapped as primary (3268155) and almost a third of our reads were either secondary (2418649) or supplementary (2437248).

**Primary alignments** are reads that only map to 1 alignment. **Secondary alignments** are when reads map to multiple locations. **Supplementary alignments** mean that minimap2 split the reads into chimeric/non-colinear segments, which can be the result of structural variation, chimeric molecules (so library prep errors?), or repetitive sequences. We'll need to run RepeatModeler to find out whether repetitive sequences are to blame for this.

That said, 2876007/3268155 (88%) of our primary reads were mapped to the reference, **which suggests contamination is not a problem**. We'll double check this after we assemble our genome by running Blobtools.







