Set of scripts to analyze ChIP-seq data.

Example runs:

1) Trim adapter sequences:

/path/to/run_trimmomatic.sh -e /dir/with/fastq(.gz)/files -a TruSeq3-PE.fa -s paired -m 512M -i 256M

I have noticed it helps when you have copied the adapter fasta file in your experiment directory.

2) Map with HISAT2 (assumbing you have build an index for the genome you wish to map the reads to)

/path/to/map_with_hisat2.sh -e /path/to/trimmed/read/files -i /path/to/genome/index/(basename of genome) -s paired -p 16 -u NO

Basename of genome could be, for example, "GRCh38.p14" (without the ".1.ht2" suffix and so on)
Here we map paired reads to the latest version of GRCh38 assembly using 16 threads and discarding the unpaired reads.

3) Mark duplicates and filter unwanted reads

/path/to/post_alignment_filtering.sh -b /path/to/mapped_reads -o /path/to/mapped_reads/filtered_reads -t 16

Part 2) Call peaks with MACS3

/path/to/macs3_callpeak.sh -e /dir/with/filtered/reads -s bam -o /output/dir/name -i N -p B -f BAMPE -d "--broad-cutoff 0.1 -q 0.05 --gsize 2862010428" -n 1-6

Here, I call peaks without an input control using the broad peak mode provided by MACS3. When using this mode, please provide a --broad-cutoff value.
