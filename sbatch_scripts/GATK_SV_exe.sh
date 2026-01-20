#!/bin/bash

################# This script takes tab-/comma-delimited file with sample information, and runs gatk-sv pipeline (https://github.com/broadinstitute/gatk-sv/tree/main) as sbatch job
################# Tab-/comma-delimited file should have the following columns: SampleID, Path/to/BAM

#### User-defined parameters (Change these as needed) ####
module load java/openjdk-17.0.2
export CROMWELL_EXE="/users/1/balay011/helper_scripts/gatk_sv_cromwell_scripts/cromwell-91.jar"
export MANIFEST="/projects/standard/venteicher_30050/balay011/gatk-sv/gatk-sv-manifest.tsv"
export OUTPUT_DIR="/scratch.global/balay011/gatk_sv_output"
export GatherSampleEvidence_WDL="/users/1/balay011/helper_scripts/gatk_sv_cromwell_scripts/GatherSampleEvidence.wdl"
export EvidenceQC_WDL="/users/1/balay011/helper_scripts/gatk_sv_cromwell_scripts/EvidenceQC.wdl"
export DEPS_ZIP="/users/1/balay011/helper_scripts/gatk_sv_cromwell_scripts/gatk-sv-deps.zip"

#### Step I: GatherSampleEvidence

# Assemble JSON file for GatherSampleEvidence for each sample in the manifest file (Change paths as needed)
mkdir -p ${OUTPUT_DIR}/JSON_files/GatherSampleEvidence
while IFS=$', \t' read -r SAMPLE_ID BAM_PATH; do
    
    [[ "$SAMPLE_ID" == "SampleID" ]] && continue
    [[ -z "$SAMPLE_ID" ]] && continue

    if [[ -f "${BAM_PATH}.bai" ]]; then
        BAI_PATH="${BAM_PATH}.bai"
    else
        BAI_PATH="${BAM_PATH%.bam}.bai"
    fi

    JSON_FILE="${OUTPUT_DIR}/JSON_files/GatherSampleEvidence/${SAMPLE_ID}_GatherSampleEvidence.json"

    cat <<EOF > "$JSON_FILE"
{
  "GatherSampleEvidence.sample_id": "$SAMPLE_ID",
  "GatherSampleEvidence.bam_or_cram_file": "$BAM_PATH",
  "GatherSampleEvidence.bam_or_cram_index": "$BAI_PATH",
  "GatherSampleEvidence.collect_coverage": true,
  "GatherSampleEvidence.collect_pesr": true,
  "GatherSampleEvidence.run_localize_reads": false,
  "GatherSampleEvidence.run_module_metrics": true,
  "GatherSampleEvidence.reference_fasta": "/projects/standard/aventeic/balay011/references/reference_genome/GRCh38.primary_assembly.genome.fa",
  "GatherSampleEvidence.reference_index": "/projects/standard/aventeic/balay011/references/reference_genome/GRCh38.primary_assembly.genome.fa.fai",
  "GatherSampleEvidence.reference_dict": "/projects/standard/aventeic/balay011/references/reference_genome/GRCh38.primary_assembly.genome.fa.dict",
  "GatherSampleEvidence.primary_contigs_list": "/projects/standard/aventeic/balay011/references/GATK_SV_files/primary_contigs.list",
  "GatherSampleEvidence.primary_contigs_fai": "/projects/standard/aventeic/balay011/references/GATK_SV_files/contig.fai",
  "GatherSampleEvidence.preprocessed_intervals": "/projects/standard/aventeic/balay011/references/GATK_SV_files/preprocessed_intervals.interval_list",
  "GatherSampleEvidence.wham_include_list_bed_file": "/projects/standard/aventeic/balay011/references/GATK_SV_files/wham_whitelist.bed",
  "GatherSampleEvidence.manta_region_bed": "/projects/standard/aventeic/balay011/references/GATK_SV_files/primary_contigs_plus_mito.bed.gz",
  "GatherSampleEvidence.manta_region_bed_index": "/projects/standard/aventeic/balay011/references/GATK_SV_files/primary_contigs_plus_mito.bed.gz.tbi",
  "GatherSampleEvidence.sd_locs_vcf": "/projects/standard/aventeic/balay011/references/dbSNP_files/All_20180418.vcf.gz",
  "GatherSampleEvidence.mei_bed": "/projects/standard/aventeic/balay011/references/GATK_SV_files/hg38.repeatmasker.mei.with_SVA.pad_50_merged.bed.gz",
  "GatherSampleEvidence.cloud_sdk_docker": "google/cloud-sdk",
  "GatherSampleEvidence.sv_pipeline_docker": "us.gcr.io/broad-dsde-methods/gatk-sv/sv-pipeline:2025-12-18-v1.1-5b84101e",
  "GatherSampleEvidence.sv_base_mini_docker": "us.gcr.io/broad-dsde-methods/gatk-sv/sv-base-mini:2024-10-25-v0.29-beta-5ea22a52",
  "GatherSampleEvidence.samtools_cloud_docker": "us.gcr.io/broad-dsde-methods/gatk-sv/samtools-cloud:2024-10-25-v0.29-beta-5ea22a52",
  "GatherSampleEvidence.genomes_in_the_cloud_docker": "us.gcr.io/broad-gotc-prod/genomes-in-the-cloud:2.3.2-1510681135",
  "GatherSampleEvidence.manta_docker": "us.gcr.io/broad-dsde-methods/gatk-sv/manta:2023-09-14-v0.28.3-beta-3f22f94d",
  "GatherSampleEvidence.wham_docker": "us.gcr.io/broad-dsde-methods/gatk-sv/wham:2024-10-25-v0.29-beta-5ea22a52",
  "GatherSampleEvidence.scramble_docker": "us.gcr.io/broad-dsde-methods/gatk-sv/scramble:2024-10-25-v0.29-beta-5ea22a52",
  "GatherSampleEvidence.gatk_docker": "us.gcr.io/broad-dsde-methods/gatk-sv/gatk:mw-gatk-sv-1eac9db"
}
EOF

    echo "Generated JSON for $SAMPLE_ID"

done < "$MANIFEST"

# Submit GatherSampleEvidence as sbatch job array
mkdir -p ${OUTPUT_DIR}/{scripts,GatherSampleEvidence}

SLURM_QCI_SCRIPT="${OUTPUT_DIR}/scripts/submit_gatk_sv_array.slurm"

cat <<EOF > "$SLURM_QCI_SCRIPT"
#!/bin/bash
#SBATCH --job-name=gatk_sv_qcI
#SBATCH --output=logs/gatk_sv_qcI_%A_%a.out
#SBATCH --error=logs/gatk_sv_qcI_%A_%a.err
#SBATCH --cpus-per-task=1
#SBATCH --mem=64G
#SBATCH --time=24:00:00

module load java/openjdk-17.0.2

LINE=\$(grep -vE '^SampleID|^$' "$MANIFEST" | sed -n "\${SLURM_ARRAY_TASK_ID}p")
SAMPLE_ID=\$(echo \$LINE | awk '{print \$1}')

JSON_INPUT="${OUTPUT_DIR}/JSON_files/GatherSampleEvidence/\${SAMPLE_ID}_GatherSampleEvidence.json"
WORK_DIR="${OUTPUT_DIR}/GatherSampleEvidence/\${SAMPLE_ID}"
mkdir -p "\$WORK_DIR"

echo "Running GatherSampleEvidence & EvidenceQC for Sample: \$SAMPLE_ID"

cd "\$WORK_DIR"
java -jar "$CROMWELL_EXE" run "$GatherSampleEvidence_WDL" -i "\$JSON_INPUT" -p "$DEPS_ZIP"
EOF

chmod +x "$SLURM_QC_SCRIPT"

NUM_SAMPLES=$(grep -vE '^SampleID|^$' "$MANIFEST" | wc -l)
echo "Submitting GatherSampleEvidence array job for $NUM_SAMPLES samples..."

sbatch --array=1-$NUM_SAMPLES "$SLURM_QC_SCRIPT"