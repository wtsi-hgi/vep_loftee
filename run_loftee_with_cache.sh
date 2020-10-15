# choose vcf file to run vep-loftee on:
work_dir=$PWD # this directory will be mounted in the container, it must contain the input/output vcf location
chmod a+rw ${work_dir} # this might be required to allow docker user to write to that dir
vcf=${work_dir}/test.vcf
out_vcf=${work_dir}/test.out.vcf

vep_release=94.5 # this must match the version/tag of the docker image in dockerhub
#see https://hub.docker.com/r/mercury/vep_loftee/tags
genome=GRCh38 # choose GRCh37 or GRCh38, must match version used to build the cache, see script make_vep_cache.sh
vep_docker_image=mercury/vep_loftee:${vep_release}

# see script make_vep_cache.sh to build cache dir:
local_vep_cache=${HOME}/vep_data_${vep_release}.${genome}
echo ${local_vep_cache}
ls ${local_vep_cache}

# loftee github files were copied to ${local_vep_cache}/Plugins/, which is mounted in docker at /opt/vep/.vep/Plugins
loftee_path=/opt/vep/.vep/Plugins/
# additional files for loftee plugin:  
human_ancestor_fa=/opt/vep/.vep/human_ancestor.fa.gz
if [ $genome = "GRCh37" ]; then                                                                        
   conservation_file=${local_vep_cache}/phylocsf_gerp.sql                                              
else                                                                                                   
   conservation_file=${local_vep_cache}/loftee.sql                                                     
fi
gerp_file=/opt/vep/.vep/GERP_scores.final.sorted.txt.gz

# now run vep-loftee:
sudo docker run -t -i \
     -v ${work_dir}:${work_dir} \
     -v ${local_vep_cache}:/opt/vep/.vep \
     -v ${local_vep_cache}:/opt/vep/.vep \
      ${vep_docker_image} \
      vep --cache --offline \
      -i ${vcf} \
      --plugin LoF,loftee_path:${loftee_path},human_ancestor_fa:${human_ancestor_fa},conservation_file:${conservation_file},gerp_file:${gerp_file} \
      --vcf -o ${out_vcf} --force_overwrite 
