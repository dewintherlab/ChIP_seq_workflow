#! /bin/bash

#--------------------------------------------------------------------------------------------------------------
# Function definitions
# Usage function
function display_help {
        echo "Author: A. Drakaki"
        echo ""
        echo "Usage: $0 -e <EXPDIR> -o <OUTDIR> -d <TEMP_DIR> -t <THREADS> -m <MEMORY> -e <EXTRA>"
        echo ""
        echo "  -e <EXPDIR>:               Directory with trimmed fastq files"
        echo ""
        echo "  -o <OUTDIR>:            Output directory"
        echo ""
        echo "  -d <TEMP_DIR>:          Temporary files will be written here when generating report images. Defaults to system temp directory if not specified. (Required)"
        echo ""
        echo "  -t <THREADS>:           Will be passed on to fastqc command. Specifies the files that can be processed simultaneously (Required)"
        echo ""
        echo "  -m <MEMORY>:            Will be passed on to fastqc command. Base amount of memory to be used, in Megabytes. Default is 512MB. (Required)"
        echo ""
        echo "  -e <EXTRA OPTS>:        Extra command line options you wish to pass to fastqc (see fastqc -h)"
        echo "                          Make sure to add all of them between to quotation marks, for example \"-c /path/to/contaminant -f fastq\""
        echo ""
        echo "  -h:                     Print this help message"
        echo ""
        echo "NOTE: make sure the files in your EXPDIR end with .fastq or .fastq.gz"
        echo ""
        exit 1
}


#--------------------------------------------------------------------------------------------------------------
# Display help and exit if not enough arguments

if [ $#  -lt 1 ]
then
        display_help
fi

# Initialize variables

EXPDIR=""
OUTDIR=""
TEMPDIR=""
MEM=""
MYTHREADS=""
EXTRA=""


#--------------------------------------------------------------------------------------------------------------
# Define options

while getopts "e:o:d:m:t:e:h" opt; do
  case $opt in
        e)
                EXPDIR=$OPTARG
                ;;
        o)
                OUTDIR=$OPTARG
                ;;
        d)
                TEMPDIR=$OPTARG
                ;;
        m)
                MEM=$OPTARG
                ;;
        t)
                MYTHREADS=$OPTARG
                ;;
        e)
                EXTRA=$OPTARG
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


# make sure fastqc is in your system
# .....

# Set some boundaries

if [ -z "$EXPDIR" ]; then
        echo "No experiment directory (-e) given, exiting"
        exit 1
fi

if [ -z "$OUTDIR" ]; then
        echo "No out directory (-o) given, exiting"
        exit 1
fi

# Check if OUTDIR exists

if [ -d "$OUTDIR" ]; then
        echo "QC reports will be written to: $OUTDIR"
else
        mkdir "$OUTDIR"
        echo "QC reports will be written to: $OUTDIR"
fi

# Run quality control after trimming

for f in $EXPDIR/*trimmed*fastq.gz; do

        echo "Running: fastqc -o $OUTDIR $f --memory $MEM -t $MYTHREADS --dir $TEMPDIR $EXTRA"
        fastqc -o $OUTDIR $f --memory $MEM -t $MYTHREADS "$EXTRA" --dir $TEMPDIR
done
wait
