#! /bin/bash

#--------------------------------------------------------------------------------------------------------------
# Function definitions
# Usage function
function display_help {
        echo "Author: A. Drakaki"
        echo ""
        echo "Usage: $0 -b <BAM DIR>"
        echo ""
        echo "  -b <BAM DIRECTORY>:             Directory where all the BAM files you wish to convert to BigWig format are stored"
        echo ""
        echo "  -h                              Print this help message"
        echo ""
        echo "NOTE: this works with the effective genome size of human hg38. Adjust to your data if you're using another organism or build"
        echo ""
        exit 1
}


#--------------------------------------------------------------------------------------------------------------
# Display help and exit if not enough arguments

if [ $#  -lt 1 ]
then
        display_help
fi

# Initialize variable

BAMDIR=""
OUTNAME=""

# Parse flags
while getopts "b:h" option; do
  case $option in

        b)
                BAMDIR="$OPTARG"
                ;;

        h)
                display_help
                ;;
        \?)
                echo "Invalid option: -$OPTARG" >&2
                exit 1
                ;;
        :)
                echo "Option -$OPTARG requires an argument." >&2
                exit 1
                ;;
  esac
done


# Convert BAM to BW and normalize the number of reads per bin
## The method used here is: Reads per genome coverage, RPGC.

cd $BAMDIR

for f in *.bam; do

        OUTNAME=($(basename $f .bam)_norm.bw)
        bamCoverage --bam $f -o $OUTNAME --binSize 20 --normalizeUsing RPGC --effectiveGenomeSize 2913022398 --extendReads -p 8
done

wait
