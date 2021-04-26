FROM perl:latest
label maintainer="kandre@ak-online.be"

RUN cpanm Carton Starman

COPY . /LockoutBoard
RUN cd /LockoutBoard && carton install --deployment
WORKDIR /LockoutBoard

EXPOSE 1701
CMD carton exec starman --port 1701 LockoutBoard/bin/app.psgi

