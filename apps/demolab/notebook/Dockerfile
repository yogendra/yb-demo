FROM jupyter/datascience-notebook:ubuntu-22.04
USER root
RUN \
    apt-get update && \
    sudo apt-get -qqy install libpq-dev python3-dev
USER 1000
RUN \
    pip install --no-cache-dir psycopg2-yugabytedb ipython-sql && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"
