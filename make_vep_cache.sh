vep_release=100.2 # this must match the version of the docker image
genome=GRCh38
vep_docker_image=4ee408888558
local_vep_cache=${HOME}/vep_data_${vep_release}.${genome}
echo ${local_vep_cache}

rm -rf ${local_vep_cache}
mkdir -p ${local_vep_cache}
chmod a+rw ${local_vep_cache}

# instructions from
# http://www.ensembl.org/info/docs/tools/vep/script/vep_download.html#docker
echo install cache
sudo docker run -t -i \
     -v ${local_vep_cache}:/opt/vep/.vep \
      ${vep_docker_image} \
      perl INSTALL.pl -a cfp -s homo_sapiens -y ${genome} --PLUGINS all
sudo chmod -R a+rw ${local_vep_cache} # required if docker user is different that regular user

# add loftee plugin to the cache

# add loftee plugin
# instructions from https://github.com/konradjk/loftee
echo add loftee plugin to cache
git clone \
    https://github.com/konradjk/loftee.git \
    tmp_clone && \
    rm -rf tmp_clone/.git* && \
    cp -r tmp_clone/* ${local_vep_cache}/Plugins/ && \
    rm -r tmp_clone

# download optional loftee files human_ancestor_fa
wget https://s3.amazonaws.com/bcbio_nextgen/human_ancestor.fa.gz -P ${local_vep_cache}/
wget https://s3.amazonaws.com/bcbio_nextgen/human_ancestor.fa.gz.fai -P ${local_vep_cache}/
wget https://s3.amazonaws.com/bcbio_nextgen/human_ancestor.fa.gz.gzi -P ${local_vep_cache}/
# download optional loftee files conservation_file
wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh37/phylocsf_gerp.sql.gz -P ${local_vep_cache}/
gunzip ${local_vep_cache}/phylocsf_gerp.sql.gz
