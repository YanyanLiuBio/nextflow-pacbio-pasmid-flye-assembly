process PYSAMSATS {
   tag "${pair_id}"
   publishDir path:  "${params.output}/per_base_data_out", mode: 'copy'

    input:
    tuple val(pair_id), path(bam), path(ref)

    output:
    tuple val(pair_id), path("${pair_id}.per.base.csv") 

  

    script:
    """

    pysamstats --type variation --format csv --fasta $ref $bam > ${pair_id}.variation.csv

    awk -F',' '
    NR==1 {
      k=0
      for(i=1; i<=NF; i++) {
        if(\$i !~ /_pp\$/) {
          keep[++k] = i
          header[k] = \$i
        }
      }
      for(i=1; i<=k; i++) {
        printf "%s%s", header[i], (i<k ? "," : "\\n")
      }
    }
    NR>1 {
      for(i=1; i<=k; i++) {
        printf "%s%s", \$keep[i], (i<k ? "," : "\\n")
      }
    }
    ' ${pair_id}.variation.csv > temp.csv
    
    awk -F',' '{ NF--; print \$0 }' OFS=',' temp.csv > ${pair_id}.per.base.csv
    """
  
  
}
