FROM python:3.9.6-buster

WORKDIR /app
COPY src .
RUN pip install -r requirements.txt


EXPOSE 80
CMD python3 server.py