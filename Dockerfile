FROM python:3.7.5-buster

RUN apt-get update && apt-get install -y --no-install-recommends \
        supervisor \
        virtualenv

# Until pyFF pull request 183 https://github.com/IdentityPython/pyFF/pull/183
# is merged and a new release cut use a special URL the causes pip to include
# the PR as if it were merged.
ENV PYFF_SRC_URL=git+https://github.com/IdentityPython/pyFF.git@refs/pull/183/merge

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
