FROM ubuntu:24.04 AS build

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update && apt-get install -y python3-pip wget libz-dev \
    && pip3 install --break-system-packages -U mammoth==1.11.0 Sphinx==9.1.0 sphinx_rtd_theme==3.1.0 oletools==0.60.2 setuptools idna

RUN sed -i 's/options.get("ignore_empty_paragraphs", True)/options.get("ignore_empty_paragraphs", False)/g' /usr/local/lib/python3.12/dist-packages/mammoth/options.py

RUN arch=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/) && wget https://github.com/jgm/pandoc/releases/download/3.9/pandoc-3.9-linux-${arch}.tar.gz
RUN arch=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/) && tar xzf pandoc-3.9-linux-${arch}.tar.gz --strip-components 1 -C /usr/local/

FROM ubuntu:24.04
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update && apt-get install -y python3 make zip 

COPY --from=build /usr/local /usr/local
COPY convert.sh /

VOLUME /u
WORKDIR /u
ENTRYPOINT ["/bin/bash", "/convert.sh"]
