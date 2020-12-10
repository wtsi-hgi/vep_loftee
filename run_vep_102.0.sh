#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

USAGE="\n\nUSAGE:\n\t $0 <input file(vcf format)>\n\n\t      The absolute path should be resolved and the output\n\t      will use the original file name but with vep.vcf in\n\t      place of the vcf in the input filename\n\t      filename must contain \"vcf\"\n\n"

if [ -z $@ ]
then
	echo -e $USAGE
        exit 1
else
	INPUT_VCF=$(realpath $1)
fi
VCF_DIR=$(dirname $INPUT_VCF)
VCF_FILE=$(basename $INPUT_VCF)
OUTPUT_VCF=$(echo $VCF_FILE | sed 's/vcf/vep.vcf/')

if  [[ ! $VCF_FILE =~ .*vcf.* ]]
then
	echo -e $USAGE
	exit 1
elif [ ! -e $VCF_FILE ]
then
	echo -e "\n\n\t   File $1 does not exist\n\n\n"
        exit 1
fi

#echo $INPUT_VCF
#echo $VCF_DIR
#echo $VCF_FILE
#echo $OUTPUT_VCF


singularity exec \
--bind $VCF_DIR:/opt/vcf \
--bind /lustre/scratch118/humgen/resources/ensembl/vep/GRCh38/vep_data:/opt/vep/.vep \
--bind /lustre/scratch118/humgen/resources/ensembl/vep/GRCh38/Plugins:/opt/vep/.vep/Plugins \
--bind /lustre/scratch118/humgen/resources/gnomAD/release-2.1.1/exomes \
--bind /lustre/scratch118/humgen/resources/cadd_scores/20201027-GRCh38_v1.6 \
--bind /lustre/scratch118/humgen/resources/SpliceAI_data_files \
/lustre/scratch118/humgen/resources/ensembl/vep/singularity_containers/vep_102.0.sif \
vep \
--cache \
--dir_cache /opt/vep/.vep/ \
--fasta /opt/vep/.vep/homo_sapiens/102_GRCh38/Homo_sapiens.GRCh38.dna.toplevel.fa.gz \
--offline \
--format vcf \
--dir_plugins /opt/vep/.vep/Plugins \
-i /opt/vcf/$VCF_FILE \
--plugin SpliceRegion,Extended \
--plugin GeneSplicer,/opt/vep/.vep/Plugins/GeneSplicer/bin/linux/genesplicer,/opt/vep/.vep/Plugins/GeneSplicer/human \
--plugin UTRannotator,/opt/vep/.vep/Plugins/uORF_starts_ends_GRCh38_PUBLIC.txt \
--plugin CADD,/lustre/scratch118/humgen/resources/cadd_scores/20201027-GRCh38_v1.6/whole_genome_SNVs.tsv.gz,/lustre/scratch118/humgen/resources/cadd_scores/20201027-GRCh38_v1.6/gnomad.genomes.r3.0.indel.tsv.gz \
--fork 4 \
--custom /lustre/scratch118/humgen/resources/gnomAD/release-2.1.1/exomes/gnomad.exomes.r2.1.1.sites.liftover_grch38.vcf.bgz,gnomAD2.1,vcf,exact,0,AF_raw,AF_popmax,AF_afr,AF_amr,AF_asj,AF_eas,AF_fin,AF_nfe,AF_oth,AF_sas  \
--plugin LoF,loftee_path:/opt/vep/.vep/Plugins,human_ancestor_fa:/opt/vep/.vep/Plugins/GRCh38_human_ancestor.fa.gz,conservation_file:/opt/vep/.vep/Plugins/loftee.sql,gerp_bigwig:/opt/vep/.vep/Plugins/gerp_conservation_scores.homo_sapiens.GRCh38.bw \
--plugin REVEL,/opt/vep/.vep/Plugins/grch38_tabbed_revel.tsv.gz \
--plugin SpliceAI,snv=/lustre/scratch118/humgen/resources/SpliceAI_data_files/spliceai_scores.raw.snv.hg38.vcf.gz,indel=/lustre/scratch118/humgen/resources/SpliceAI_data_files/spliceai_scores.raw.indel.hg38.vcf.gz \
--vcf \
-o /opt/vcf/$OUTPUT_VCF \
--compress_output bgzip \
--allele_number \
--verbose 

