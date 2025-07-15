#!/bin/bash

input=s3://seqwell-projects/20250328_pacbio_fornax/demux_output/bc20250228/merged_fastq/portion_3/*.fastq.gz
output=s3://seqwell-users/yanyan/pacbio_plasmid_assemble/flye_assemble_trycycler_tertiant3

/software/nextflow-align/nextflow run \
-c nextflow.config_local \
main.nf \
--input $input \
--output $output \
-bg -resume

#-work-dir 's3://seqwell-users/yanyan/temp-work-dir/work' \
