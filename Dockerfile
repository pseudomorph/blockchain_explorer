FROM alpine

RUN apk update
RUN apk add python3 py3-pip


COPY src/blockchain_explorer /app
COPY bin/entrypoint /bin/entrypoint
RUN chmod +x /bin/entrypoint
WORKDIR /app
RUN pip3 install -r requirements.txt

ENTRYPOINT ["/bin/entrypoint" ]
CMD ["./manage.py", "runserver", "0.0.0.0:8000"]