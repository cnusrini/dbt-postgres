FROM python:3.11-slim

WORKDIR /usr/app

RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    dbt-core==1.8.6 \
    dbt-postgres==1.8.2

ENTRYPOINT ["dbt"]