FROM python:3.6-slim

RUN mkdir -p /opt/calc

WORKDIR /opt/calc

COPY requirements.txt ./
RUN pip install -r requirements.txt

COPY app ./app

EXPOSE 5000
