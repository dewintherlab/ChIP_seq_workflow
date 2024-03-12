Set of scripts to analyze ChIP-seq data.

Example runs:

1) Trim adapter sequences:

/path/to/run_trimmomatic.sh -e /dir/with/fastq(.gz)/files -a TruSeq3-PE.fa -s paired -m 512M -i 256M

I have noticed it helps when you have copied the adapter fasta file in your experiment directory.

2) 
