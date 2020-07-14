FROM ensemblorg/ensembl-vep:release_100.2

WORKDIR /opt/vep/src

USER root
RUN apt update && apt install wget libcurl4-openssl-dev git -y
RUN chmod -R a+rw /opt/vep/src

USER vep
WORKDIR /opt/vep/src
RUN ls -ltra
RUN wget https://github.com/samtools/samtools/releases/download/1.10/samtools-1.10.tar.bz2
RUN tar -xvjf samtools-1.10.tar.bz2
RUN mkdir /opt/vep/samtools
WORKDIR /opt/vep/src/samtools-1.10
RUN ./configure --without-curses --prefix=/opt/vep/samtools
RUN make
RUN make install
ENV PATH /opt/vep/samtools/bin:$PATH
RUN echo $PATH
RUN ls -ltra /opt/vep/samtools
RUN samtools --version


WORKDIR /opt/vep/src
RUN git clone https://github.com/DBD-SQLite/DBD-SQLite.git 
WORKDIR /opt/vep/src/DBD-SQLite
RUN mkdir /opt/vep/DBD-SQLite
RUN perl Makefile.PL PREFIX=/opt/vep/DBD-SQLite
RUN make
RUN make test
RUN make install
ENV PERL5LIB /opt/vep/DBD-SQLite/lib/x86_64-linux-gnu/perl/5.26.1/:$PERL5LIB
RUN echo $PERL5LIB
RUN ls -ltra /opt/vep/src/ensembl-vep
RUN echo $PATH
WORKDIR /opt/vep/src/ensembl-vep