
FROM python

RUN \
  pip install awscli

WORKDIR /
COPY exec.sh /

CMD [ "./exec.sh" ]