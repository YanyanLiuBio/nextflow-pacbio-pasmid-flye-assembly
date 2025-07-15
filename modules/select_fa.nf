process SELECT_FA {
    memory '7 GB' 

    tag "${pair_id}"

    input:
    tuple val(pair_id), path(fa)

    output:
    tuple val(pair_id), path("${pair_id}.longest.fasta")

    script:
    """
    # Determine the length of the longest sequence
    max_len=\$(awk '/^>/ {if (seqlen) print seqlen; seqlen=0; next} {seqlen += length(\$0)} END {print seqlen}' ${fa} | sort -nr | head -n 1)

    # Use bbduk.sh to filter sequences by the maximum length
    bbduk.sh -Xmx2g in=${fa} out=${pair_id}.longest.fasta minlength=\$max_len maxlength=\$max_len
    """
}
