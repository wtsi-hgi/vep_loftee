# GeneSplicer exectable needs to be compiled to work in the vep container

cd /opt/vep/.vep/Plugins/GeneSplicer/sources
make
cp genesplicer ../bin/linux/
