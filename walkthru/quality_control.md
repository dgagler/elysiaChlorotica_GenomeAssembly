
# mid-October to early November 2026
- received Iso-Seq data mid-Oct
- received a first round of HiFi data late October (about 9gigabytes of data)
- received a second round of HiFi data early November (about 1.5Gb of data)
	- this data was all based on AmpliFi. need to get specific PCR primers they used
- they send follow-up about Hi-C still not mapping well, which implies that a new draft assembly based on the new HiFi data is not good. they send the following assembly statistics:
	- Total assembly size: approximately 983 Mb
	- Total contigs: 14,790
	- Contig N50: approximately 98 kb
	- Longest contig: approximately 1.83 Mb
	- Contigs longer than 1 Mb: only 2
	- **ie BAD!**

## What I've Done:
- downloaded all data via AWS
- seem to have run out of space on huxley/nas4 so had to download to huxley/nas5
- downloaded data to physical laptop
- uploaded it all to Goodheart Lab Teams under Data_and_Notes/Dylan
- tried and failed to get hifiasm to run
	- got errors saying "counted 0 distinct kmers" followed by a segmentation fault
- began to suspect this is because the data came as unaligned bams and not fastq files
	- converted bams to fastqs via samtools
- currently rerunning hifiasm
	- it worked!
- **i moved all raw and trimmed fastq files for the bulk RNA and srWGS data to NAS5! due to me hitting my measly 250gb disk quota already**

## Things to check for assembly quality and troubleshooting moving forward:
- get basic assembly stats via seqkit stats on pacbio fastqs
- run GenomeScope2 to estimate genome size, heterozygosity, repeat content, etc.
- run Kraken2 to look at contamination %
- evaluate kmer profile 
- check read depth distribution and insert-size profile to see if read coverage is uneven due to AmpliFi protocol 
- see this discussion: https://github.com/chhylp123/hifiasm/issues/385

## Data sanity check
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
Let's now do a basic estimate of sequencing depth based on the # of bp in our fastq files divided by the estimated genome size. We know the # of bps in each fastq file from seqkit stats: 25.429Gb and 3.832Gb. The current draft genome of Elysia chlorotica is 0.56Gb.

So 25.429/0.56Gb and 3.832/0.56Gb = 45.4x and 6.8x, for a total of 52.2x average coverage. This is fine.

I then ran fastqc on them to get overall quality assessments. The sequence quality is pretty good, hanging around 38 Q-score
![[fastqc_example.png]]

Now let's do a sanity check. Let's take the first read in the first fastq file and BLAST it. ANd we get...questionable results. Top hits are all coronaviruses, but the query cover is very low. So these reads are barely aligning to anything, so they are probably nonsense reads, possibly errors from PCR. There are several Elysia genomes out there so we would expect to be hitting those.![[Screenshot 2026-11-12 at 8.28.56 AM.png]]
Ok. Let's try the second read anddd same thing. Now we'll try the last read in the first fastq. Yep, nothing. I also randomly subsampled 10 sequences and blasted them and all the same. Best we have are an aplysia and physella sequence hit here and there
![[Screenshot 2026-11-12 at 8.32.27 AM.png]]
Let's try the 2nd fastq. Same thing. Ok, well that sucks.

This is probably enough to get our shit resequenced (or not have to pay for the results) already, but I will do my due dilligence and also finish running jellyfish and genomescope for a kmer histogram, and then run kraken2 for pre-assembly (ie fastq) contamination estimation or blobtools for post-assembly contamination estimation 

Kraken2 status:
- installed on HPC
- should be ok with standard DB for contam...but it takes 500Gb of space to make. trying to do this on a fresh nas5 which should have about 500Gb of space
- 



