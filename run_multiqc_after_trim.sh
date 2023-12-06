#! /bin/bash

#--------------------------------------------------------------------------------------------------------------
# Function definitions
# Usage function
function display_help {
        echo "Author: A. Drakaki"
        echo ""
        echo "Usage: $0 -d <OPTIONS> -o <OUTDIR> -e <EXPERIMENT DIR>"
        echo ""
        echo "  -d <OPTIONS>:                 Add here all the options to pass on to multiqc (see \"multiqc -h\" to adjust to your needs)"
        echo "                          Please provide all options between two quotation marks"
        echo ""
        echo "  -e <EXPDIR>:                    Path to directory with fastqc reports you want to aggregate with multiqc"
        echo ""
        echo "  -o <OUTDIR>:                    Output directory"
        echo ""
        echo "  -h                              Print this help message"
        echo ""
        echo "NOTE: In case you want to provide the \"--file-list\" option to specify multiple paths with fastqc reports, add this to \"-o\" and leave \"-e\" out"
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

EXTRA=""
EXPDIR=""
OUTDIR=""

# Parse flags
while getopts "d:e:o:h" option; do
  case $option in

        d)
                EXTRA="$OPTARG"
                ;;

        e)
                EXPDIR="$OPTARG"
                ;;
        o)
                OUTDIR="$OPTARG"
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

# Check if multiqc is in the system

if command -v multiqc &> /dev/null; then
    echo "multiqc is installed. Proceeding with the script."
else
    echo "Error: multiqc is not installed."
fi

which multiqc > /dev/null || { echo "Multiqc cannot be found in your system's PATH, exiting..."; exit 1; }

# Check if OUTDIR exists

if [[ -d "$OUTDIR" ]]; then
        echo "Multiqc reports will be written to: $OUTDIR"
else
        mkdir $OUTDIR
        echo "Multiqc reports will be written to: $OUTDIR"
fi

# Run command

if [[ -z "$EXPDIR" ]]; then

        echo "Running: multiqc $EXTRA -o $OUTDIR"
        multiqc $EXTRA -o "$OUTDIR"
else

        echo "Running: multiqc $EXTRA -o $OUTDIR $EXPDIR"
        multiqc $EXTRA -o "$OUTDIR" "$EXPDIR"
fi

wait
