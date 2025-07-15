process QUAST { 
  
  publishDir path: "${params.output}/quast_out", mode:"copy"
  
  container "staphb/quast:5.3.0"
  
  input:
  tuple val(sample_ID), path (fa)
  
  
  output:
  path("*")
  
 """
 quast.py -o ${sample_ID}_quast_output $fa
 """

}
