fq1=$1
fq2=$2
list=$3
cutcols=${4:-1,2}

if [ -z "$fq1" ] || [ -z "$fq2" ]; then
    echo "Usage: $0 <fq1> <fq2> [list] [cutcols]"
    echo "  <fq1>      : First FASTQ file"
    echo "  <fq2>      : Second FASTQ file"
    echo "  [list]     : Optional list file for subset extraction"
    echo "  [cutcols]  : Optional columns for diff (default: 1,2; e.g. 1,2,4 for id, seq, qval)"
    exit 1
fi

if [ ! -f "$fq1" ]; then
    echo "Error: File '$fq1' not found."
    exit 1
fi
if [ ! -f "$fq2" ]; then
    echo "Error: File '$fq2' not found."
    exit 1
fi

if ! command -v seqtk &> /dev/null; then
    echo "Error: seqtk not found in PATH."
    exit 1
fi

dir=$(basename "$fq1")_$(basename "$fq2")_diff

if [ -d "$dir" ]; then
    echo "Directory exists"
    exit 1
fi

logfile="$dir/fqdiff.log"

mkdir -p "$dir"
touch $logfile
echo "mkdir -p \"$dir\"" >> "$logfile"

# If $list is given, extract subsets
if [ -n "$list" ]; then
    if [ ! -f "$list" ]; then
        echo "Error: List file '$list' not found."
        exit 1
    fi
    echo "seqtk subseq \"$fq1\" \"$list\" > \"$dir/$fq1.subset\"" >> "$logfile"
    seqtk subseq "$fq1" "$list" > "$dir/$fq1.subset"
    if [ $? -ne 0 ]; then
        echo "Error: seqtk subseq failed for '$fq1' with list '$list'."
        exit 1
    fi
    echo "seqtk subseq \"$fq2\" \"$list\" > \"$dir/$fq2.subset\"" >> "$logfile"
    seqtk subseq "$fq2" "$list" > "$dir/$fq2.subset"
    if [ $? -ne 0 ]; then
        echo "Error: seqtk subseq failed for '$fq2' with list '$list'."
        exit 1
    fi
    fq1_input="$dir/$fq1.subset"
    fq2_input="$dir/$fq2.subset"
else
    fq1_input="$fq1"
    fq2_input="$fq2"
fi

echo "paste - - - - < \"$fq1_input\" | sort > \"$dir/$(basename "$fq1_input").sorted\"" >> "$logfile"
paste - - - - < "$fq1_input" | sort > "$dir/$(basename "$fq1_input").sorted"
echo "paste - - - - < \"$fq2_input\" | sort > \"$dir/$(basename "$fq2_input").sorted\"" >> "$logfile"
paste - - - - < "$fq2_input" | sort > "$dir/$(basename "$fq2_input").sorted"

echo "diff <(cut -f$cutcols \"$dir/$(basename \"$fq1_input\").sorted\") <(cut -f$cutcols \"$dir/$(basename \"$fq2_input\").sorted\") > \"$dir/diff" >> "$logfile"
diff <(cut -f$cutcols "$dir/$(basename "$fq1_input").sorted") <(cut -f$cutcols "$dir/$(basename "$fq2_input").sorted") > "$dir"/diff

