FROM perl:latest
LABEL maintainer="kandre@ak-online.be"
LABEL org.opencontainers.image.source=https://github.com/hssb-racers/lockoutboard

RUN cpanm Carton Starman

COPY . /LockoutBoard
WORKDIR /LockoutBoard
RUN carton install --deployment

EXPOSE 1701
ENTRYPOINT [ "/LockoutBoard/docker-entrypoint.sh" ]

