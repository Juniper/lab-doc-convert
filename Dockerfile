FROM ubuntu:24.04 AS build

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update && apt-get install -y python3-pip wget libz-dev \
    && pip3 install --break-system-packages -U mammoth==1.9.1 Sphinx==8.2.3 sphinx_rtd_theme==3.0.2 oletools==0.60.2 setuptools idna

RUN sed -i 's/options.get("ignore_empty_paragraphs", True)/options.get("ignore_empty_paragraphs", False)/g' /usr/local/lib/python3.12/dist-packages/mammoth/options.py

RUN wget https://github.com/jgm/pandoc/releases/download/3.7.0.2/pandoc-3.7.0.2-linux-amd64.tar.gz
RUN tar xzf pandoc-3.7.0.2-linux-amd64.tar.gz --strip-components 1 -C /usr/local/

FROM ubuntu:24.04
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update && apt-get install -y python3 make zip 

COPY --from=build /usr/local /usr/local
COPY convert.sh /

VOLUME /u
WORKDIR /u
ENTRYPOINT ["/bin/bash", "/convert.sh"]
