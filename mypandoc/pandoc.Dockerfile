# build with: docker build -f pandoc.Dockerfile -t mypandoc:latest .
# this adds the lua filters which allows nice things like graphviz
#FROM pandoc/latex:3.1-ubuntu
FROM pandoc/latex:edge-ubuntu

WORKDIR /filters

RUN wget https://github.com/pandoc/lua-filters/releases/download/v2021-11-05/lua-filters.tar.gz && ls -al && \
      tar -xvf lua-filters.tar.gz #&& chmod -R 666 .
RUN apt update && apt-get install git graphviz default-jre -y && \
      tlmgr update --self && tlmgr install tcolorbox environ tikzfill pdfcol listingsutf8 collection-fontsrecommended newunicodechar noto-emoji
# install plantuml and some extra packages
RUN wget https://github.com/plantuml/plantuml/releases/download/v1.2023.12/plantuml-gplv2-1.2023.12.jar && mv plantuml-gplv2-1.2023.12.jar /bin/plantuml.jar && \
  wget https://github.com/awslabs/aws-icons-for-plantuml/archive/refs/tags/v17.0.tar.gz && \
  mkdir /temp/awslabs -p && tar -xvf v17.0.tar.gz -C /temp/awslabs && \
  mkdir /plantuml && mv /temp/awslabs/aws-icons-for-plantuml-17.0 /plantuml/awslabs && \
  cd /plantuml && git clone https://github.com/plantuml/plantuml.git

#RUN (groupadd -r -g 1000 appuser || echo "group exists already") && useradd -m -r -u 1000 -g appuser appuser
USER 1000:1000

ENV PLANTUML=/bin/plantuml.jar

WORKDIR /data
