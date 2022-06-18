FROM python:3.9

ARG PROJECT

RUN apt-get update && apt-get install -y ffmpeg rsync
WORKDIR /opt/${PROJECT}
COPY ./ /opt/${PROJECT}
RUN python -m pip install -r requirements.txt

COPY docker-config/bashrc /root/.bashrc
