process MINIMAP2 {

    input:
      tuple val(pair_id), path(fq), path(fa)

    output:
      tuple val(pair_id), path("${pair_id}.bam"), emit: bam
      path ("*.csv"), emit: metrics

    script:
    """
    if [ -s "$fa" ]; then
        # Choose preset: map-pb for PacBio (CLR or HiFi)
        minimap2 -t 4 -a -x map-pb "$fa" "$fq" \\
        | samtools view -bh -F 2048 - \\
        | samtools sort -o ${pair_id}.bam

        samtools index ${pair_id}.bam

        samtools depth -a ${pair_id}.bam > ${pair_id}.depth.csv
        samtools view -c ${pair_id}.bam > ${pair_id}.count.csv
    else
        touch ${pair_id}.depth.csv
        touch ${pair_id}.count.csv
        touch ${pair_id}.bam
    fi
    """
}

