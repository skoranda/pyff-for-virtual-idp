FROM python:3.7.6-buster

RUN apt-get update && apt-get install -y --no-install-recommends \
        supervisor \
        virtualenv

# Use the head of master on February 3, 2020.
ENV PYFF_SRC_URL=git+https://github.com/IdentityPython/pyFF.git@a17e5435392f1bef5a3d5854fbd2ebbdbfa2dfbe

RUN mkdir -p /opt/pyff \
    && adduser --home /opt/pyff --no-create-home --system pyff --group \
    && virtualenv /opt/pyff --no-site-packages --python=python3 \
    && . /opt/pyff/bin/activate \
    && pip install --upgrade pip \
    && pip install ${PYFF_SRC_URL} \
    && chown -R pyff:pyff /opt/pyff

COPY supervisord.conf /usr/local/etc/supervisord.conf
COPY pyff-start.sh /usr/local/bin/pyff-start.sh
COPY gunicorn_sighup.py /opt/pyff/gunicorn_sighup.py
COPY gunicorn_sighup_logger.yaml /opt/pyff/gunicorn_sighup_logger.yaml

WORKDIR /opt/pyff

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/usr/local/etc/supervisord.conf"]
