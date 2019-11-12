#!/usr/bin/env bash

# Default values.
if [ -z "${PYFF_DATADIR}" ]; then
    PYFF_DATADIR=/etc/pyff
fi

if [ -z "${PYFF_GUNICORN_BIND}" ]; then
    PYFF_GUNICORN_BIND=0.0.0.0:8080
fi

if [ -z "${PYFF_GUNICORN_LOG_CONFIG}" ]; then
    PYFF_GUNICORN_LOG_CONFIG=logger.ini
fi

if [ -z "${PYFF_GUNICORN_PID_FILE}" ]; then
    PYFF_GUNICORN_PID_FILE=/tmp/gunicorn.pid
fi

if [ -z "${PYFF_GUNICORN_THREADS}" ]; then
    PYFF_GUNICORN_THREADS=4
fi

if [ -z "${PYFF_METADATA_SIGNING_CERT}" ]; then
    PYFF_METADATA_SIGNING_CERT=metadata-signer.crt
fi

if [ -z "${PYFF_METADATA_SIGNING_KEY}" ]; then
    PYFF_METADATA_SIGNING_KEY=metadata-signer.key
fi

if [ -z "${PYFF_REDIS_HOST}" ]; then
    PYFF_REDIS_HOST=localhost
fi

if [ -z "${PYFF_REDIS_PORT}" ]; then
    PYFF_REDIS_PORT=6379
fi

if [ -z "${PYFF_STORE_CLASS}" ]; then
    PYFF_STORE_CLASS=pyff.store:RedisWhooshStore
fi

if [ -z "${PYFF_SCHEDULER_JOB_STORE}" ]; then
    PYFF_SCHEDULER_JOB_STORE=redis
fi

if [ -z "${PYFF_UPDATE_FREQUENCY}" ]; then
    PYFF_UPDATE_FREQUENCY=28800
fi

mkdir -p ${PYFF_DATADIR} && cd ${PYFF_DATADIR}

# Cannot start without a pipeline.
if [ -z "${PYFF_PIPELINE}" ]; then
    echo "PYFF_PIPELINE environment variable must be defined"
    exit 1
fi

# Set permissions for pyff user to read signing cert and key.
chown pyff:pyff ${PYFF_METADATA_SIGNING_CERT}
chown pyff:pyff ${PYFF_METADATA_SIGNING_KEY}
chmod 644 ${PYFF_METADATA_SIGNING_CERT}
chmod 600 ${PYFF_METADATA_SIGNING_KEY}

source /opt/pyff/bin/activate

exec gunicorn \
    --log-config ${PYFF_GUNICORN_LOG_CONFIG} \
    --bind ${PYFF_GUNICORN_BIND} \
    --timeout 600 \
    -e PYFF_CACHE_TTL=1 \
    -e PYFF_PIPELINE=${PYFF_PIPELINE} \
    -e PYFF_UPDATE_FREQUENCY=${PYFF_UPDATE_FREQUENCY} \
    -e PYFF_PUBLIC_URL=http://127.0.0.1:8080 \
    -e PYFF_STORE_CLASS=${PYFF_STORE_CLASS} \
    -e PYFF_SCHEDULER_JOB_STORE=${PYFF_SCHEDULER_JOB_STORE} \
    -e PYFF_REDIS_HOST=${PYFF_REDIS_HOST} \
    -e PYFF_REDIS_PORT=${PYFF_REDIS_PORT} \
    --workers 1 \
    --worker-class=gthread \
    --threads ${PYFF_GUNICORN_THREADS} \
    --worker-tmp-dir=/dev/shm \
    --pid ${PYFF_GUNICORN_PID_FILE} \
    pyff.wsgi:app
