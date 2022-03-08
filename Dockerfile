FROM ubuntu:20.04 as build

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update && apt-get install -y python3-pip wget libz-dev \ 
    && pip3 install -U mammoth==1.4.18 Sphinx==4.4.0 sphinx_rtd_theme==1.0.0 oletools==0.60 setuptools==39.1.0 idna==2.5

RUN sed -i 's/options.get("ignore_empty_paragraphs", True)/options.get("ignore_empty_paragraphs", False)/g' /usr/local/lib/python3.8/dist-packages/mammoth/options.py

RUN wget https://github.com/jgm/pandoc/releases/download/2.17.1.1/pandoc-2.17.1.1-linux-amd64.tar.gz 
RUN tar xzf pandoc-2.17.1.1-linux-amd64.tar.gz --strip-components 1 -C /usr/local/

FROM ubuntu:20.04
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update && apt-get install -y python3 make zip 

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y python3-distutils

COPY --from=build /usr/local /usr/local
COPY convert.sh /

VOLUME /u
WORKDIR /u
ENTRYPOINT ["/bin/bash", "/convert.sh"]
