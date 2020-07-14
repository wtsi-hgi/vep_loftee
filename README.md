# vep_loftee

This image supports the Loftee plugin by adding samtools and DBD-SQlite perl module on top of the official VEP image
It is available in Dockerhub at  
https://hub.docker.com/r/mercury/vep_loftee/tags

first use `make_vep_cache.sh` to download the docker image, build the cache, add Loftee plugin and genome files 
then use` run_loftee_with_cache.sh` to test run on a vcf (not provided).
