# nextflow-pacbio-pasmid-flye-assembly

[![Nextflow Workflow Tests](https://github.com/YanyanLiuBio/nextflow-pacbio-pasmid-flye-assembly/actions/workflows/nextflow-ci.yml/badge.svg?branch=main)](https://github.com/YanyanLiuBio/nextflow-pacbio-pasmid-flye-assembly/actions/workflows/nextflow-ci.yml?query=branch%3Amain)
[![Nextflow](https://img.shields.io/badge/Nextflow%20DSL2-%E2%89%A523.04.0-blue.svg)](https://www.nextflow.io/)


## Overview

This Nextflow pipeline performs automated plasmid assembly from PacBio long-read sequencing data using the Flye assembler as the core assembly engine. The pipeline implements a comprehensive workflow that includes read filtering, downsampling, assembly, consensus generation, circularization, annotation, and quality assessment.

## Pipeline Architecture

The workflow follows a modular design with the following key components:

### Core Assembly Strategy
- **Primary Assembler**: Flye - optimized for long-read assembly of circular DNA elements
- **Consensus Generation**: Trycycler - creates high-quality consensus sequences from multiple assemblies
- **Circularization**: Circlator minimus2 - ensures proper circular contig formation
- **Quality Control**: Multi-stage filtering and validation

## Workflow Steps

### 1. Input Preparation and Read Filtering

**Length Range Filtering**
- Reads length ranges from `length_ranges.csv` configuration file
- Applies size-based filtering to retain reads within specified ranges
- Helps remove very short fragments and excessive long reads that may impact assembly quality

**Input Format**
- Expects compressed FASTQ files (`*fastq.gz`) in the specified input directory
- Sample identification based on filename parsing

### 2. Read Processing

**Downsampling**
- Reduces read coverage to optimal levels for assembly
- Prevents computational bottlenecks while maintaining assembly quality
- Configurable coverage targets

### 3. Primary Assembly

**Flye Assembly**
- Utilizes Flye assembler specifically configured for plasmid assembly
- Optimized for circular DNA elements and repetitive sequences
- Generates initial contigs with associated assembly graphs

**Contig Selection**
- First selection step (`SELECT_FA1`) filters contigs based on length criteria
- Focuses on longer contigs likely to represent complete or near-complete plasmids

### 4. Circularization

**Circlator Processing**
- Applies Circlator minimus2 to improve circular contig formation
- Corrects potential assembly breaks at circular junction points
- Essential for proper plasmid topology representation

### 5. Consensus Generation

**Trycycler Integration**
- Groups related contigs by sample identifier
- Generates high-quality consensus sequences
- Reconciles differences between multiple assembly attempts

**Consensus Filtering**
- Second selection step (`SELECT_FA2`) ensures quality consensus sequences
- Filters samples with excessive contig numbers that may indicate assembly issues

### 6. Annotation and Analysis

**Plasmid Annotation**
- **Plannotate**: Provides comprehensive plasmid-specific gene annotation
- Identifies resistance genes, replication origins, and other functional elements
- Generates GenBank format output for downstream analysis

**Plasmid Mapping**
- **PlasmidMap**: Creates visual representations of annotated plasmids
- Generates publication-ready circular maps

### 7. Quality Assessment

**Assembly Metrics**
- **QUAST**: Provides detailed assembly statistics and quality metrics
- Evaluates assembly completeness and accuracy

**Read Alignment Analysis**
- **Minimap2**: Aligns original reads back to assembled sequences
- **PysamStats**: Generates detailed alignment statistics and coverage analysis
- Replaces BAM read count analysis for improved accuracy

**Comprehensive Reporting**
- **Summarize**: Aggregates all metrics and statistics into final reports
- Combines alignment metrics with contig length information

## Configuration Requirements

### Input Files
- **FASTQ Files**: PacBio long-read sequencing data in compressed format
- **Length Ranges**: CSV file defining acceptable read length ranges

### Key Parameters
- `params.input`: Directory containing input FASTQ files
- Length filtering ranges defined in `length_ranges.csv`

## Output Structure

The pipeline generates several categories of output:

### Assembly Products
- High-quality consensus plasmid sequences (FASTA)
- Circularized and polished contigs

### Annotations
- GenBank files with comprehensive gene annotations
- Functional element identification

### Quality Reports
- Assembly statistics and metrics
- Read alignment coverage analysis
- Comprehensive summary reports

### Visualizations
- Circular plasmid maps
- Quality assessment plots

## Technical Considerations

### Computational Resources
- Designed for parallel processing of multiple samples
- Memory requirements scale with genome size and read coverage
- Flye assembly is the most computationally intensive step

### Quality Control Features
- Multi-stage filtering prevents low-quality assemblies from propagating
- Consensus generation improves final sequence accuracy
- Comprehensive quality metrics enable result validation

### Flexibility
- Modular design allows for component replacement or modification
- Configurable parameters for different experimental conditions
- Supports batch processing of multiple plasmid samples

## Pipeline Advantages

1. **Accuracy**: Combination of Flye assembly with Trycycler consensus generation
2. **Completeness**: Specific optimizations for circular plasmid assembly
3. **Annotation**: Integrated plasmid-specific gene annotation
4. **Quality Control**: Multiple validation and filtering steps
5. **Automation**: Fully automated workflow from raw reads to annotated assemblies
6. **Scalability**: Designed for high-throughput plasmid characterization

This pipeline provides a robust, automated solution for high-quality plasmid assembly from PacBio sequencing data, suitable for both research applications and routine plasmid characterization workflows.
