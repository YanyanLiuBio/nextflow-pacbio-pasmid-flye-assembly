process TRYCYCLER_CONSENSUS {
    errorStrategy 'ignore'
    tag "${sample_id}"
    publishDir "${params.output}/trycycler_consensus", mode: "copy"
    input:
    tuple val(sample_id), path(assemblies), path(reads)

    output:
    tuple val(sample_id), path("*trycycler_consensus.fasta"), emit: fasta
    tuple val(sample_id), path("*length_report.tsv"), emit: length_report
    path("*.contig.length.csv"), emit: contig_length

    script:
    """
    set -euo pipefail

    # Step 1: Rename files with prefix (original logic)
    mkdir -p renamed
    for f in *.fasta; do
        prefix=\$(basename "\$f" .fasta)
        awk -v p="\$prefix" '/^>/ {\$0=">"p"_"substr(\$0,2)} 1' "\$f" > renamed/"\$f"
    done
    mv renamed/* .

    # Step 2: Initialize variables
    declare -A length_counts=()
    declare -A file_lengths=()
    top1_length=""
    current_len=""

    # Step 3: Calculate lengths and build frequency table
    for f in *.fasta; do
        # Calculate sequence length (remove header and newlines)
        len=\$(grep -v '^>' "\$f" | tr -d '\n' | wc -c)
        file_lengths["\$f"]=\$len
        length_counts["\$len"]=\$((length_counts["\$len"] + 1))
    done

    # Step 4: Find the most common length (top1)
    if [ \${#length_counts[@]} -gt 0 ]; then
        top1_length=\$(printf "%s\\n" "\${!length_counts[@]}" | sort -nr | \\
            while read len; do echo "\$len \${length_counts[\$len]}"; done | \\
            sort -k2,2nr | head -n1 | awk '{print \$1}')
    fi

    # Step 5: Filter files in three stages
    mkdir -p filtered

    for f in "\${!file_lengths[@]}"; do
        current_len=\${file_lengths[\$f]}
        keep_file=true

        # Rule 1: Remove if exact double or triple of any other length
        for l in "\${!length_counts[@]}"; do
            if [[ \$current_len -eq \$((l * 2)) ]] || \\
               [[ \$current_len -eq \$((l * 3)) ]]; then
                keep_file=false
                break
            fi
        done

        # Rule 2: Only keep top1 most common length or 20bp away
        if (( current_len < top1_length - 20 || current_len > top1_length + 20 )); then
            keep_file=false
        fi

        # Copy if passed all filters
        if \$keep_file; then
            cp "\$f" "filtered/"
        fi
    done

    # Step 6: Prepare final output
    rm -f *.fasta
    mv filtered/*.fasta . 2>/dev/null || :

    # Step 7: Generate length report
    echo -e "Length\\tCount" >  ${sample_id}.length_report.tsv
    if [ \${#length_counts[@]} -gt 0 ]; then
        printf "%s\\n" "\${!length_counts[@]}" | sort -nr | \\
            while read len; do echo -e "\$len\\t\${length_counts[\$len]}"; done >>  ${sample_id}.length_report.tsv
    fi

    # Cleanup
    rm -rf renamed filtered

    echo "=== Filtering Summary ===" >&2
    if [ -n "\$top1_length" ]; then
        echo "Most common length kept: \$top1_length (\${length_counts[\$top1_length]} files)" >&2
    fi
    echo "Total files after filtering: \$(ls -1 *.fasta 2>/dev/null | wc -l)" >&2
    
    
    
    
    
    # Step 1: Cluster
    trycycler cluster --assemblies *.fasta --reads ${reads} --out_dir trycycler_clusters

    # Step 2–4: Reconcile, MSA, Consensus
    for cluster_dir in trycycler_clusters/cluster_*; do
        echo "Processing \$cluster_dir"

        # Step 2: Reconcile (must run first to generate 2_all_seqs.fasta)
        trycycler reconcile -c "\$cluster_dir" --reads "${reads}"

        contig_file="\$cluster_dir/2_all_seqs.fasta"
        if [ -f "\$contig_file" ]; then
            contig_count=\$(grep -c "^>" "\$contig_file")
            if [ "\$contig_count" -ge 2 ]; then
                # Step 3: MSA
                trycycler msa -c "\$cluster_dir"

                # Optional safeguard for consensus step
                if [ ! -f "\$cluster_dir/4_reads.fastq" ]; then
                    cp ${reads} "\$cluster_dir/4_reads.fastq"
                fi

                # Step 4: Consensus
                trycycler consensus -c "\$cluster_dir"
            else
                echo "Skipping \$cluster_dir: only \$contig_count contig(s) after reconcile"
            fi
        else
            echo "Skipping \$cluster_dir: \$contig_file not found"
        fi
    done

    # Step 5: Merge consensus
    cat trycycler_clusters/cluster_*/7_final_consensus.fasta > ${sample_id}.trycycler_consensus.fasta
      
      
      
    awk -v sid="${sample_id}" '
        /^>/ {
            if (seq) {
                print sid, name, length(seq)
            }
            name = substr(\$0, 2)
            seq = ""
            next
        }
        { seq = seq \$0 }
        END {
            if (seq) {
                print sid, name, length(seq)
            }
        }
    ' OFS="\\t" "${sample_id}.trycycler_consensus.fasta" | tr '\t' ','> ${sample_id}.contig.length.csv
    
    """
}

