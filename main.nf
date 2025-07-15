#!/usr/bin/env nextflow


include { LENGTH_FILTER_RANGE } from './modules/length_filter_range.nf'
include { DOWNSAMPLE } from './modules/downsample.nf'
include { FLYE_ASSEMBLE } from './modules/flye_assemble.nf'
include { TRYCYCLER_CONSENSUS } from './modules/trycycler.nf'
include { BAM_READ_COUNT } from './modules/bam_read_count.nf'
include { MINIMAP2 } from './modules/minimap2.nf'
include { ANALYZE_BAM_READ_COUNT } from './modules/analyze_bam_read_count.nf'
include { PLANNOTATE } from './modules/plannotate.nf'
include { PLASMIDMAP } from './modules/plasmidMap.nf'
include { CIRCLATOR_MINIMUS2 } from './modules/circlator_minimus2.nf'
include { QUAST } from './modules/quast.nf'
include { SUMMARIZE } from './modules/summarize.nf'
include { SELECT_FA as SELECT_FA1 } from './modules/select_fa.nf'
include { SELECT_FA as SELECT_FA2 } from './modules/select_fa.nf'
include { PYSAMSATS } from './modules/pysamstats.nf'


workflow {
  
  
    // Read length ranges from file
Channel
    .fromPath('length_ranges.tsv')
    .splitCsv(header:true, sep:'\t')
    .map { row -> tuple(row.min, row.max) }
    .set { length_ranges }

  
    fq_ch = Channel.fromPath( params.input + "/*fastq.gz" )
                   .map{ it-> tuple(it.baseName.replace("fastq", ""), it)}
                 //  .take(1)                 
    fq_ch.view() 
    fq_and_ranges = fq_ch
       .combine(length_ranges)
       
    filtered_ch = LENGTH_FILTER_RANGE(fq_and_ranges)
  
    downsampled_fq_ch = DOWNSAMPLE(filtered_ch)
  
    flye_ch = FLYE_ASSEMBLE(downsampled_fq_ch)
   
    long_fa_ch = SELECT_FA1 (flye_ch.flye_fasta)
  
    circ_ch = CIRCLATOR_MINIMUS2( long_fa_ch)
   
    circ_ch_fa_modified = circ_ch.fasta
                          .map{ it -> tuple( it[0].tokenize("_")[0],  it[1]) }
                          .groupTuple( )
    circ_ch_fa_modified.view()
    //fq_ch.view()   
    trycycler_in = circ_ch_fa_modified.join( fq_ch )


    //trycycler_in.view()
    //add the trycycler Step
    trycycler_ch = TRYCYCLER_CONSENSUS( trycycler_in)

   //need a filter, if more than two contigs from one samplefrom tycycler , just skip
    trycycler_filtered = SELECT_FA2(trycycler_ch.fasta)

    trycycler_filtered.view()
    gbk_ch = PLANNOTATE( trycycler_filtered)

    align_in = fq_ch.join( trycycler_filtered)

    PLASMIDMAP( gbk_ch.collect())  

    quast_ch = QUAST(trycycler_filtered) 

    minimap2_ch = MINIMAP2(align_in)
  
//    bam_read_count_report = BAM_READ_COUNT(minimap2_ch.bam.join(trycycler_filtered))

    PYSAMSATS(minimap2_ch.bam.join(trycycler_filtered))  //the results are different from bam_read_count, bam read count error is half
//    ANALYZE_BAM_READ_COUNT(bam_read_count_report)

    SUMMARIZE(minimap2_ch.metrics.collect())    
    
  
}


