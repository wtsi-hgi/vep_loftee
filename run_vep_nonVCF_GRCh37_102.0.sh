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
--bind /lustre/scratch118/humgen/resources/ensembl/vep/GRCh37/vep_data:/opt/vep/.vep \
--bind /lustre/scratch118/humgen/resources/ensembl/vep/GRCh37/vep_data/Plugins:/opt/vep/.vep/Plugins \
--bind /lustre/scratch118/humgen/resources/gnomAD/release-2.1.1/exomes \
--bind /lustre/scratch118/humgen/resources/cadd_scores/20201027-GRCh37_v1.6 \
--bind /lustre/scratch118/humgen/resources/SpliceAI_data_files \
/lustre/scratch118/humgen/resources/ensembl/vep/singularity_containers/vep_102.0.sif \
vep \
-a GRCh37 \
--cache \
--dir_cache /opt/vep/.vep/ \
--format hgvs \
--refseq \
--fasta /opt/vep/.vep/homo_sapiens/102_GRCh37/Homo_sapiens.GRCh37.75.dna.primary_assembly.fa.gz \
--dir_plugins /opt/vep/.vep/Plugins \
-i /opt/vcf/$VCF_FILE \
--plugin SpliceRegion,Extended \
--plugin GeneSplicer,/opt/vep/.vep/Plugins/GeneSplicer/bin/linux/genesplicer,/opt/vep/.vep/Plugins/GeneSplicer/human \
--plugin UTRannotator,/opt/vep/.vep/Plugins/uORF_5UTR_GRCh37_PUBLIC.txt \
--plugin CADD,/lustre/scratch118/humgen/resources/cadd_scores/20201027-GRCh37_v1.6/whole_genome_SNVs.tsv.gz,/lustre/scratch118/humgen/resources/cadd_scores/20201027-GRCh37_v1.6/whole_genome_SNVs.tsv.gz \
--fork 4 \
--everything \
--plugin LoF,loftee_path:/opt/vep/.vep/Plugins,human_ancestor_fa:/opt/vep/.vep/Plugins/grch37_human_ancestor.fa.gz,conservation_file:/opt/vep/.vep/Plugins/phylocsf_gerp.sql  \
--plugin REVEL,/opt/vep/.vep/Plugins/grch37_tabbed_revel.tsv.gz \
--plugin SpliceAI,snv=/lustre/scratch118/humgen/resources/SpliceAI_data_files/spliceai_scores.raw.snv.hg19.vcf.gz,indel=/lustre/scratch118/humgen/resources/SpliceAI_data_files/spliceai_scores.raw.indel.hg19.vcf.gz \
--vcf \
-o /opt/vcf/$OUTPUT_VCF \
--compress_output bgzip \
--allele_number \
--verbose 

