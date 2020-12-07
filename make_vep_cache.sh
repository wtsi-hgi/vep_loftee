vep_release=$(git rev-parse --abbrev-ref HEAD) # this should  match the version/tag of the docker image in dockerhub
                                               #see https://hub.docker.com/r/mercury/vep_loftee/tags

vep_cache_release=$(echo ${vep_release} | sed "s/\.[[:digit:]]\+//")
genome=GRCh38 # choose GRCh37 or GRCh38
vep_docker_image=mercury/vep_loftee:${vep_release}
vep_singularity_image=vep_loftee_${vep_release}.sif
vep_dir="/lustre/scratch118/humgen/resources/ensembl/vep"

# choose where to build the cache, e.g. in ${HOME} :
default_vep_cache=/lustre/scratch118/humgen/resources/ensembl/vep/${genome}/vep_data  #/homo_sapiens/${vep_cache}
echo ${default_vep_cache}

#rm -rf ${local_vep_cache}
#mkdir -p ${local_vep_cache}
#chmod a+rw ${local_vep_cache}

# use singularity to pull the docker image from dockerhub and build the equivalent Singularity container

cd ${vep_dir}/singularity_containers/
/software/singularity-v3.6.4/bin/singularity pull docker://${vep_docker_image}



# instructions taken from
# http://www.ensembl.org/info/docs/tools/vep/script/vep_download.html#docker
echo install cache
/software/singularity-v3.6.4/bin/singularity exec \
     -B ${default_vep_cache}:/opt/vep/.vep \
      ${vep_singularity_image} \
      perl INSTALL.pl -a cf -s homo_sapiens -y ${genome}


#sudo chmod -R a+rw ${local_vep_cache} # required if docker user is different that regular user
echo install Plugins
/software/singularity-v3.6.4/bin/singularity exec \
     -B ${default_vep_cache}:/opt/vep/.vep \
      ${vep_singularity_image} \
      perl INSTALL.pl -a p --PLUGINS all
# add loftee plugin to the cache

# add loftee plugin
# instructions from https://github.com/konradjk/loftee
echo add loftee plugin to cache
cd ${default_vep_cache}
git clone --single-branch --branch grch38 https://github.com/konradjk/loftee.git tmp_clone
cp -rf tmp_clone/* ${default_vep_cache}/Plugins/
rm -rf tmp_clone

# download optional loftee files human_ancestor_fa
if [ $genome = "GRCh37" ]; then
   [[ -f ${default_vep_cache}/Plugins/grch37_human_ancestor.fa.gz ]] || wget https://s3.amazonaws.com/bcbio_nextgen/human_ancestor.fa.gz -P ${default_vep_cache}/Plugins/ -O grch37_human_ancestor.fa.gz
   [[ -f ${default_vep_cache}/Plugins/grch37_human_ancestor.fa.gz.fai ]] || wget https://s3.amazonaws.com/bcbio_nextgen/human_ancestor.fa.gz.fai -P ${default_vep_cache}/Plugins/ -O human_ancestor.fa.gz.fai
   [[ -f ${default_vep_cache}/Plugins/grch37_human_ancestor.fa.gz.gzi ]] || wget https://s3.amazonaws.com/bcbio_nextgen/human_ancestor.fa.gz.gzi -P ${default_vep_cache}/Plugins/ -O human_ancestor.fa.gz.gzi
   # download optional loftee files conservation_file
   [[ -f ${default_vep_cache}/Plugins/phylocsf_gerp.sql ]] || wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh37/phylocsf_gerp.sql.gz -P ${default_vep_cache}/Plugins/ && gunzip ${default_vep_cache}/Plugins/phylocsf_gerp.sql.gz
   [[ -f ${default_vep_cache}/Plugins/GERP_scores.exons.txt.gz ]] || wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh37/GERP_scores.exons.txt.gz -P ${default_vep_cache}/Plugins/                                     
   [[ -f ${default_vep_cache}/Plugins/GERP_scores.final.sorted.txt.gz ]] || wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh37/GERP_scores.final.sorted.txt.gz -P ${default_vep_cache}/Plugins/                              
   [[ -f ${default_vep_cache}/Plugins/GERP_scores.final.sorted.txt.gz.tbi ]] || wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh37/GERP_scores.final.sorted.txt.gz.tbi -P ${default_vep_cache}/Plugins/                   
else
   [[ -f ${default_vep_cache}/Plugins/grch38_human_ancestor.fa.gz ]] || wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh38/human_ancestor.fa.gz -P ${default_vep_cache}/ -O grch38_human_ancestor.fa.gz
   [[ -f ${default_vep_cache}/Plugins/grch38_human_ancestor.fa.gz.fai ]] || wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh38/human_ancestor.fa.gz.fai -P ${default_vep_cache}/ -O grch38_human_ancestor.fa.gz.fai
   [[ -f ${default_vep_cache}/Plugins/grch38_human_ancestor.fa.gz.gzi ]] || wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh38/human_ancestor.fa.gz.gzi -P ${default_vep_cache}/ -O grch38_human_ancestor.fa.gz.gzi
   # download optional loftee files conservation_file
   [[ -f ${default_vep_cache}/Plugins/gerp_conservation_scores.homo_sapiens.GRCh38.bw ]] || wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh38/gerp_conservation_scores.homo_sapiens.GRCh38.bw -P ${default_vep_cache}/Plugins/
   [[ -f ${default_vep_cache}/Plugins/loftee.sql ]] || wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh38/loftee.sql.gz -P ${default_vep_cache}/Plugins/ && gunzip ${default_vep_cache}/Plugins/loftee.sql.gz
fi
