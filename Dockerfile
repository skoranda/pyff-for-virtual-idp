FROM python:3.7.6-buster

RUN apt-get update && apt-get install -y --no-install-recommends \
        supervisor \
        virtualenv

# Use a particular commit:
ENV PYFF_SRC_URL=git+https://github.com/IdentityPython/pyFF.git@7705880df77538f5d34976da5e26db1f80a75e53

RUN mkdir -p /opt/pyff \
    && adduser --home /opt/pyff --no-create-home --system pyff --group \
    && virtualenv /opt/pyff --no-site-packages --python=python3 \
    && . /opt/pyff/bin/activate \
    && pip install --upgrade pip \
    && pip install ${PYFF_SRC_URL} \
    && chown -R pyff:pyff /opt/pyff

# Until Issue 193
#
# https://github.com/IdentityPython/pyFF/issues/193
#
# is resolved or the Shibboleth SP changes what it sends
# in the Accept header monkey patch.
COPY api.py /opt/pyff/lib/python3.7/site-packages/pyff/api.py

COPY supervisord.conf /usr/local/etc/supervisord.conf
COPY pyff-start.sh /usr/local/bin/pyff-start.sh
COPY gunicorn_sighup.py /opt/pyff/gunicorn_sighup.py
COPY gunicorn_sighup_logger.yaml /opt/pyff/gunicorn_sighup_logger.yaml

WORKDIR /opt/pyff

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/usr/local/etc/supervisord.conf"]
