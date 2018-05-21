FROM cockroachdb/cockroach

RUN mkdir /cockroach/certs
ADD certs /cockroach/certs/
WORKDIR /cockroach
