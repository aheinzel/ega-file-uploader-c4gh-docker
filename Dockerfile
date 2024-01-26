FROM alpine:3.19.0

RUN apk add --no-cache bash python3 py3-pip parallel lftp openssh-client && \
   echo "set sftp:auto-confirm yes" >> /etc/lftp.conf

RUN pip install --break-system-packages crypt4gh

ADD crypt4gh_rec_ega /usr/local/bin/crypt4gh_rec_ega

ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]