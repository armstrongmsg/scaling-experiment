FROM ubuntu

RUN apt-get update
RUN apt-get install -y software-properties-common python
RUN apt-get install -y python-setuptools python-pip
RUN pip install Flask

COPY factorial.py /

ENTRYPOINT ["python"]
CMD ["factorial.py"]
