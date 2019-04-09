FROM ubuntu

RUN apt-get update
RUN apt-get install -y software-properties-common python
RUN apt-get install -y python-setuptools python-pip
RUN pip install redis

RUN mkdir /factorial
COPY factorial /factorial

