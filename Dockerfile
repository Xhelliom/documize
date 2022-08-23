FROM ubuntu:20.04 as build-env

RUN apt-get update -y \
    && apt-get install -y wget \
    && wget -O /usr/local/bin/documize https://community-downloads.s3.us-east-2.amazonaws.com/documize-community-plus-linux-amd64 \
    && chmod +x /usr/local/bin/documize

FROM gcr.io/distroless/base-debian10
COPY --from=build-env /usr/local/bin/documize /

ENV DOCUMIZESALT="somethingsupersecret" \
DOCUMIZEDB="host=documize-postgres-s port=5432 sslmode=disable user=testuser password=testpassword123 dbname=testdb"

ADD start.sh /usr/local/bin/
ENTRYPOINT ["./start.sh"]
