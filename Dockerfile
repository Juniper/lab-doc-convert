FROM ubuntu:18.04 as build

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update && apt-get install -y python3-pip wget libz-dev \
    && pip3 install -U mammoth Sphinx sphinx_rtd_theme oletools 

RUN sed -i 's/options.get("ignore_empty_paragraphs", True)/options.get("ignore_empty_paragraphs", False)/g' /usr/local/lib/python3.6/dist-packages/mammoth/options.py

RUN wget https://github.com/jgm/pandoc/releases/download/2.9.2.1/pandoc-2.9.2.1-linux-amd64.tar.gz 
RUN tar xzf pandoc-2.9.2.1-linux-amd64.tar.gz --strip-components 1 -C /usr/local/

FROM ubuntu:18.04
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update && apt-get install -y python3 make zip

COPY --from=build /usr/local /usr/local
COPY convert.sh /

VOLUME /u
WORKDIR /u
ENTRYPOINT ["/bin/bash", "/convert.sh"]
