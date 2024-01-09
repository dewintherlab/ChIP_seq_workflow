#! /bin/bash
#--------------------------------------------------------------------------------------------------------------
# Function definitions
# Usage function
function display_help {
        echo "Author: A. Drakaki"
        echo ""
        echo "Script to submit a peak calling job with MACS3 to a HPC."
        echo ""
        echo "Usage: $0 -e <EXPERIMENT DIR> -o <OUTDIR> -i <INPUT> -p <BROAD OR NARROW PEAK MODE> -f <FORMAT> -n <SAMPLE FIELDS TO CONSIDER> -d <EXTRA>"
        echo ""
        echo "  -e <EXPDIR>:          Directory with samples. Make sure this directory only contains the files that you want to call peaks for"
        echo ""
        echo "  -s <FILE SUFFIX>        Extension/suffix of your files in the EXPDIR. For example, bam, sam, bed, etc. Default is bam."
        echo ""
        echo "  -o <OUTDIR>:            Peaks files will be written in this directory. If it doesn't already exist, it will be created"
        echo ""
        echo "  -i <INPUT>:           Y or N, depending on whether input or mock IP samples exist in your EXPDIR. The script will search for the keywords: Input, IgG to identify controls."
        echo "                  Please, alter the script to include other types of controls, e.g. negative control, non-specific Ab. Default is N"
        echo ""
        echo "  -p <PEAK MODE>: B for BROAD (will result in using the --broad option in macs3 callpeak), N for NARROW"
        echo ""
        echo "  -f <FORMAT>:            Sample format which will be passed to --format, see macs3 documentation for options. Recommended: BAM, or BAMPE for paired-end reads. Required argument."
        echo ""
        echo "  -d <EXTRAs>:          Extra options for macs3, e.g. p- and q-values. Please provide all options between two quotation marks, for example \"-q 1e-05 --ext-size 200\" "
        echo "                  Make sure this option contains AT LEAST one parameter"
        echo "                  When using this script with broad peak mode, don't forget to set a q/p-value and a --broad-cutoff with the -d option"
        echo ""
        echo "  -n <#SAMPLE FIELDS TO CONSIDER>:        How many fields (separated by a punctuation character) in the sample name are important to consider for peak calling"
        echo "                                  For example, given the sample \"ARPE_WT_FOXO_ChIP_S1_filtered.bam\" and -n 1-4, the script will break the sample name in 7 fields,"
        echo "                                  and keep the first 4 to search for keywords to perform peak calling. You can also use it as such: -n 1,3-5,"
        echo "                                  in which case the first and the third to fifth fields will be considered."
        echo ""
        echo "  -h:                   Print this help message"
        echo ""
        exit 1
}

#--------------------------------------------------------------------------------------------------------------
# Display help and exit if not enough arguments

if [ $#  -lt 1 ]; then

        display_help
fi

# Initialize variables

EXPDIR=""
SUFFIX=""
OUTDIR=""
INPUT=""
PEAK=""
FORMAT=""
EXTRA=""
NFIELDS=""


#--------------------------------------------------------------------------------------------------------------
# Define options

while getopts "e:s:o:i:p:f:d:n:h" opt; do
  case $opt in
        e)
                EXPDIR=$OPTARG
                ;;
        s)
                SUFFIX=$OPTARG
                ;;
        o)
                OUTDIR=$OPTARG
                ;;
        i)
                INPUT=$OPTARG
                ;;
        d)
                EXTRA=$OPTARG
                ;;
        p)
                PEAK=$OPTARG
                ;;
        f)
                FORMAT=$OPTARG
                ;;
        n)
                NFIELDS=$OPTARG
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

# Set exit status for required options
## expdir
if [ -z "$EXPDIR" ]; then
        echo "You have not provided any experiment directory, exiting"
        exit 1
fi

## suffix
if [ -z "$SUFFIX" ]; then
        echo "You have not specified the file suffix. By default, the script will search for BAM files in your EXPDIR."
        SUFFIX="bam"
fi

## format
if [ -z "$FORMAT" ]; then
        echo "You have not clarified the sample format, exiting"
        exit 1
fi

## peak
if [ -z "$PEAK" ]; then
        echo "No peak mode provided. Default to N (for narrow)"
        PEAK="N"
fi

## input
if [ -z "$INPUT" ]; then
        INPUT="N"
        echo "Default to NO input"
fi

## nfields
if [ -z "$NFIELDS" ]; then
        echo "You have not specified the number of sample fields to consider for peak calling, exiting"
        exit 1
fi

## outdir
### no outdir specified
if [ -z "$OUTDIR" ]; then
        echo "You have not specified an outout directory. Peak files will be written to $EXPDIR"
        OUTDIR="$EXPDIR"
fi
### outdir specified but does not exist
if [[ ! -d "$OUTDIR" ]]; then
        mkdir "$OUTDIR"
fi

# check tools
# which macs3 > /dev/null || { echo "MACS3 was not found in your system's PATH, exiting..."; exit 1; }

echo "Experiment directory: $EXPDIR"
echo "File extension $SUFFIX"
echo "Output path: $OUTDIR"
echo "Samples are in the following format: $FORMAT"
echo "Number of fields to keep: $NFIELDS"
echo "Are there input samples? $INPUT"
echo "Broad or narrow peak mode? $PEAK"
echo "Extra options for peak calling: $EXTRA"

##### Determine sample/input pairs #####

if [ "$INPUT" == "Y" ]; then

# input array
inputs=()
inputs=($(ls "$EXPDIR" | grep -hiE ".*IgG.*${SUFFIX}$|.*Input.*${SUFFIX}$"))

echo "The following files are assumed to be your inputs: "
for i in "${inputs[@]}"; do echo "$i"; done

# and non-inputs

samples=()
samples=($(ls "$EXPDIR" | grep -vhiE ".*IgG.*|.*Input.*" | grep -hiE ".*${SUFFIX}$"))

echo "The following files are assumed to be your samples of interest:"
for f in "${samples[@]}"; do echo "$f"; done
echo ""
        ## create sample-input pairings
        counter=0

        ### Array to store pairings
        declare -A pairings

        ### write pairings to file
        DATE="$(date +"%Y_%m_%d")"
        pairs_file="$OUTDIR/${DATE}_pairs.txt"

        echo '#! /bin/bash' > "$pairs_file"
        echo 'declare -A pairings' > "$pairs_file"

        for f in "${samples[@]}"; do
        let counter++
        PS3="For $f, choose the correct input (enter a number): "

        select input in "${inputs[@]}"; do
                if [ -n "$input" ]; then
                        echo "Selected input for $f: $input"

                        # Store pairing in the associative array
                        pairings["$f"]="$input"
                        echo "pairings[\"$f\"]=\"$input\"" >> "$pairs_file"

                        break
                else
                        echo "Invalid option."
                fi
        done
        done

fi
##########################################

# Set max job time
MAXTIME=10:00:00 # change if needed

# path to job script
JOB="/trinity/home/adrakaki/scripts/ChIP_workflow/macs3_callpeak_new.job"

# time of submission
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# submit
sbatch --time=$MAXTIME --export=ALL,EXPDIR=$EXPDIR,SUFFIX=$SUFFIX,OUTDIR=$OUTDIR,INPUT=$INPUT,FORMAT=$FORMAT,PEAK=$PEAK,EXTRA="$EXTRA",NFIELDS="$NFIELDS",pairs_file="$pairs_file" $JOB

