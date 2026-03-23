FROM python:3.5.2-slim

ARG _WORKDIR=/app

ARG APP_PORT=8000

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1


WORKDIR ${_WORKDIR}


COPY . ${_WORKDIR}

RUN pip install -r requirements.txt --no-cache-dir \
     && chmod +x ${_WORKDIR}/entrypoint.sh \
     && sed -i 's/\r$//g' ${_WORKDIR}/entrypoint.sh

EXPOSE ${APP_PORT}

ENTRYPOINT ["/app/entrypoint.sh"]


