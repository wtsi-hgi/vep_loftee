command -v tabix >/dev/null 2>&1 || { echo >&2 "Tabix is required but it's not installed.  Aborting."; exit 1; }


vep_release=$(git rev-parse --abbrev-ref HEAD) # this should  match the version/tag of the docker image in dockerhub
                                               #see https://hub.docker.com/r/mercury/vep_loftee/tags

vep_cache_release=$(echo ${vep_release} | sed "s/\.[[:digit:]]\+//")
genome=GRCh37 # choose GRCh37 or GRCh38
vep_docker_image=mercury/vep_loftee:${vep_release}
vep_singularity_image=vep_loftee_${vep_release}.sif
vep_dir="/lustre/scratch118/humgen/resources/ensembl/vep"

# choose where to build the cache, e.g. in ${HOME} :
default_vep_cache=${vep_dir}/${genome}/vep_data  #/homo_sapiens/${vep_cache}
if [[ -d "${default_vep_cache}" ]]
    then
        echo ${default_vep_cache}
    else
        mkdir -p ${default_vep_cache}
        echo ${default_vep_cache}
fi

echo ${default_vep_cache}

#rm -rf ${local_vep_cache}
#mkdir -p ${local_vep_cache}
#chmod a+rw ${local_vep_cache}

# use singularity to pull the docker image from dockerhub and build the equivalent Singularity container
if [[ -d "${vep_dir}/singularity_containers" ]]
    then
        cd ${vep_dir}/singularity_containers/
        [[ -f ${vep_singularity_image} ]] || /software/singularity-v3.6.4/bin/singularity pull docker://${vep_docker_image}
    else
        mkdir ${vep_dir}/singularity_containers
        cd ${vep_dir}/singularity_containers/
        [[ -f ${vep_singularity_image} ]] || /software/singularity-v3.6.4/bin/singularity pull docker://${vep_docker_image}
fi




# instructions taken from
# http://www.ensembl.org/info/docs/tools/vep/script/vep_download.html#docker
if [[ -d ${default_vep_cache}/homo_sapiens/${vep_cache_release}_${genome} ]]
  then
      echo "vep cache ${default_vep_cache}/homo_sapiens/${vep_cache_release}_${genome}"
  else
      echo install cache
      /software/singularity-v3.6.4/bin/singularity exec \
      -B ${default_vep_cache}:/opt/vep/.vep \
      ${vep_singularity_image} \
      perl /opt/vep/src/ensembl-vep/INSTALL.pl -d /opt/vep/.vep -c /opt/vep/.vep  -a cf -s homo_sapiens -y ${genome} --CACHE_VERSION ${vep_cache_release}
fi	      


#sudo chmod -R a+rw ${local_vep_cache} # required if docker user is different that regular user
if [[ -d ${default_vep_cache}/Plugins ]]
  then
     echo "vep Plugins ${default_vep_cache}/Plugins"
  else
     echo install Plugins
     /software/singularity-v3.6.4/bin/singularity exec \
     -B ${default_vep_cache}:/opt/vep/.vep \
     ${vep_singularity_image} \
     perl /opt/vep/src/ensembl-vep/INSTALL.pl -d /opt/vep/.vep -a p --PLUGINS all --PLUGINSDIR /opt/vep/.vep/Plugins
fi
# add loftee plugin to the cache

# add loftee plugin
# instructions from https://github.com/konradjk/loftee

if [[ -f ${default_vep_cache}/Plugins/LoF.pm ]]
   then
       loftee_md5=$(md5sum ${default_vep_cache}/Plugins/LoF.pm | awk '{print$1}')
   else
       loftee_md5="missing"
fi


echo add loftee plugin to cache
if [ $genome = "GRCh37" ]
    then
        echo "Checking loftee for ${genome}"
        if [ $loftee_md5 = "b36c6afe5eac055717524e7761a87207" ]
           then
               echo "loftee installed for ${genome} at ${default_vep_cache}/Plugins/LoF.pm"
               if [[ -f ${default_vep_cache}/Plugins/utr_splice.pl ]]
                  then
                     echo "Loftee auxilliary files seem to be installed"
		  else
                     echo add loftee auxilliary files to cache
                     cd ${default_vep_cache}
                     git clone  https://github.com/konradjk/loftee.git tmp_clone
                     cp -rf tmp_clone/* ${default_vep_cache}/Plugins/
                     rm -rf tmp_clone
	       fi
       fi

    else
        echo "Checking loftee for ${genome}"
        loftee_md5=$(md5sum ${default_vep_cache}/Plugins/LoF.pm | awk '{print$1}')
       if [ $loftee_md5 = "f739c86776aebee76ed8e2c4b8214b8a" ]
           then
               echo "loftee installed for ${genome} at ${default_vep_cache}/Plugins/LoF.pm"
               if [[ -f ${default_vep_cache}/Plugins/utr_splice.pl ]]
                  then
	             echo "Loftee auxilliary files seem to be installed"
		  else
                     echo add loftee auxilliary files to cache
                     cd ${default_vep_cache}
                     git clone --single-branch --branch grch38 https://github.com/konradjk/loftee.git tmp_clone
                     cp -rf tmp_clone/* ${default_vep_cache}/Plugins/
                     rm -rf tmp_clone
	       fi     
       fi
fi

# download optional loftee files human_ancestor_fa
if [ $genome = "GRCh37" ]; then
   if [[ -f ${default_vep_cache}/Plugins/grch37_human_ancestor.fa.gz ]]
       then
           echo using loftee data file ${default_vep_cache}/Plugins/grch37_human_ancestor.fa.gz
       else
           wget https://s3.amazonaws.com/bcbio_nextgen/human_ancestor.fa.gz -P ${default_vep_cache}/Plugins/
           mv ${default_vep_cache}/Plugins/human_ancestor.fa.gz ${default_vep_cache}/Plugins/grch37_human_ancestor.fa.gz
   fi
   if [[ -f ${default_vep_cache}/Plugins/grch37_human_ancestor.fa.gz.fai ]]
       then
           echo using loftee data file ${default_vep_cache}/Plugins/grch37_human_ancestor.fa.gz.fai
       else
           wget https://s3.amazonaws.com/bcbio_nextgen/human_ancestor.fa.gz.fai -P ${default_vep_cache}/Plugins/
           mv ${default_vep_cache}/Plugins/human_ancestor.fa.gz.fai ${default_vep_cache}/Plugins/grch37_human_ancestor.fa.gz.fai
   fi
   if [[ -f ${default_vep_cache}/Plugins/grch37_human_ancestor.fa.gz.gzi ]]
        then
            echo using loftee data file ${default_vep_cache}/Plugins/grch37_human_ancestor.fa.gz.gzi
        else
            wget https://s3.amazonaws.com/bcbio_nextgen/human_ancestor.fa.gz.gzi -P ${default_vep_cache}/Plugins/
            mv ${default_vep_cache}/Plugins/human_ancestor.fa.gz.gzi ${default_vep_cache}/Plugins/grch37_human_ancestor.fa.gz.gzi
   fi
   # download optional loftee files conservation_file
   if [[ -f ${default_vep_cache}/Plugins/phylocsf_gerp.sql ]]
      then
              echo "loftee conservation_file installed at ${default_vep_cache}/Plugins/phylocsf_gerp.sql"
      else
              wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh37/phylocsf_gerp.sql.gz -P ${default_vep_cache}/Plugins/
              gunzip ${default_vep_cache}/Plugins/phylocsf_gerp.sql.gz
   fi
   [[ -f ${default_vep_cache}/Plugins/GERP_scores.exons.txt.gz ]] || wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh37/GERP_scores.exons.txt.gz -P ${default_vep_cache}/Plugins/                                     
   [[ -f ${default_vep_cache}/Plugins/GERP_scores.final.sorted.txt.gz ]] || wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh37/GERP_scores.final.sorted.txt.gz -P ${default_vep_cache}/Plugins/                              
   [[ -f ${default_vep_cache}/Plugins/GERP_scores.final.sorted.txt.gz.tbi ]] || wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh37/GERP_scores.final.sorted.txt.gz.tbi -P ${default_vep_cache}/Plugins/                   
else
   if [[ -f ${default_vep_cache}/Plugins/grch38_human_ancestor.fa.gz ]]
       then
           echo using loftee data file ${default_vep_cache}/Plugins/grch38_human_ancestor.fa.gz
       else
            wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh38/human_ancestor.fa.gz -P ${default_vep_cache}/Plugins
            mv ${default_vep_cache}/Plugins/human_ancestor.fa.gz ${default_vep_cache}/Plugins/grch38_human_ancestor.fa.gz
   fi
   if [[ -f ${default_vep_cache}/Plugins/grch38_human_ancestor.fa.gz.fai ]]
       then
           echo using loftee data file ${default_vep_cache}/Plugins/grch38_human_ancestor.fa.gz.fai
       else
           wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh38/human_ancestor.fa.gz.fai -P ${default_vep_cache}/Plugins
           mv ${default_vep_cache}/Plugins/human_ancestor.fa.gz.fai ${default_vep_cache}/Plugins/grch38_human_ancestor.fa.gz.fai
   fi
   if [[ -f ${default_vep_cache}/Plugins/grch38_human_ancestor.fa.gz.gzi ]]
       then
           echo using loftee data file ${default_vep_cache}/Plugins/grch38_human_ancestor.fa.gz.gzi
       else
           wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh38/human_ancestor.fa.gz.gzi -P ${default_vep_cache}/Plugins
           mv ${default_vep_cache}/Plugins/human_ancestor.fa.gz.gzi ${default_vep_cache}/Plugins/grch38_human_ancestor.fa.gz.gzi
   fi
   # download optional loftee files conservation_file
   [[ -f ${default_vep_cache}/Plugins/gerp_conservation_scores.homo_sapiens.GRCh38.bw ]] || wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh38/gerp_conservation_scores.homo_sapiens.GRCh38.bw -P ${default_vep_cache}/Plugins/
    if [[ -f ${default_vep_cache}/Plugins/loftee.sql ]]
      then
           echo "loftee loftee.sql installed at ${default_vep_cache}/Plugins/loftee.sql"
      else
           wget https://personal.broadinstitute.org/konradk/loftee_data/GRCh38/loftee.sql.gz -P ${default_vep_cache}/Plugins/
	   gunzip ${default_vep_cache}/Plugins/loftee.sql.gz
    fi
fi

# Install UTRannotator Plugin

if [[ -f ${default_vep_cache}/Plugins/UTRannotator.pm ]]
   then
       echo "UTRannotator installed at ${default_vep_cache}/Plugins/UTRannotator.pm"
   else
      git clone https://github.com/ImperialCardioGenetics/UTRannotator.git tmp_clone_UTR
      cp -rf tmp_clone_UTR/* ${default_vep_cache}/Plugins/
      rm -rf tmp_clone_UTR
fi

# Get REVEL data file

if [ $genome = "GRCh37" ]
    then
        if [[ -f ${default_vep_cache}/Plugins/grch37_tabbed_revel.tsv.gz ]]
	   then
     	       echo "REVEL data file is available at ${default_vep_cache}/Plugins/grch37_tabbed_revel.tsv.gz"
           else
	       wget https://rothsj06.u.hpc.mssm.edu/revel_grch38_all_chromosomes.csv.zip -P ${default_vep_cache}/Plugins/
               zcat ${default_vep_cache}/Plugins/revel_grch38_all_chromosomes.csv.zip | tr "," "\t" | sed '1s/.*/#&/' | awk 'BEGIN{OFS="\t"}{print$1,$2,$4,$5,$6,$7,$8}' | bgzip  > ${default_vep_cache}/Plugins/grch37_tabbed_revel.tsv.gz
               tabix -f -s 1 -b 2 -e 2 ${default_vep_cache}/Plugins/grch37_tabbed_revel.tsv.gz 
  	       rm ${default_vep_cache}/Plugins/revel_grch38_all_chromosomes.csv.zip
        fi
     else	  
	 if [[ -f ${default_vep_cache}/Plugins/grch38_tabbed_revel.tsv.gz ]]
	    then
	        echo "REVEL data file is available at ${default_vep_cache}/Plugins/grch38_tabbed_revel.tsv.gz"
	    else
	        wget https://rothsj06.u.hpc.mssm.edu/revel_grch38_all_chromosomes.csv.zip -P ${default_vep_cache}/Plugins/
                zcat ${default_vep_cache}/Plugins/revel_grch38_all_chromosomes.csv.zip | tr "," "\t" | sed '1s/.*/#&/' | awk 'BEGIN{OFS="\t"}{if ($3 != ".")print$1,$3,$4,$5,$6,$7,$8}' | sed 's/#chr/0000#chr/' | sort -Vk1,2 | sed 's/0000#chr/#chr/' | bgzip  > ${default_vep_cache}/Plugins/grch38_tabbed_revel.tsv.gz
                tabix -f -s 1 -b 2 -e 2 ${default_vep_cache}/Plugins/grch38_tabbed_revel.tsv.gz
                rm ${default_vep_cache}/Plugins/revel_grch38_all_chromosomes.csv.zip
         fi  
fi

# Get GeneSplicer binary and training data

if [[ -d ${default_vep_cache}/Plugins/GeneSplicer ]]
     then
             echo "GeneSplicer installed at ${default_vep_cache}/Plugins/GeneSplicer"
     else
             wget ftp://ftp.ccb.jhu.edu/pub/software/genesplicer/GeneSplicer.tar.gz -P ${default_vep_cache}/Plugins/
             cd ${default_vep_cache}/Plugins
             tar -xzf GeneSplicer.tar.gz
             rm GeneSplicer.tar.gz
             /software/singularity-v3.6.4/bin/singularity exec -B ${default_vep_cache}:/opt/vep/.vep -B ${vep_dir}/vep_loftee/:/vep_loftee ${vep_dir}/singularity_containers/${vep_singularity_image} /bin/bash /vep_loftee/compile_GeneSplicer.sh
fi

