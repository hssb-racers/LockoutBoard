FROM perl:latest
LABEL maintainer="kandre@ak-online.be"

RUN cpanm Carton Starman

COPY . /LockoutBoard
WORKDIR /LockoutBoard
RUN carton install --deployment

EXPOSE 1701
ENTRYPOINT /LockoutBoard/docker-entrypoint.sh

