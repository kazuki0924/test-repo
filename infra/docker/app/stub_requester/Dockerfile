FROM python:3.13.0-bookworm

ARG DEST_DOMAIN="stub-intra-api"
ARG DEST_PORT=8000
ARG SLEEP_SECONDS=5
ENV DEST_URI="http://${DEST_DOMAIN}:${DEST_PORT}"

CMD ["sh", "-c", "count=0; while [ ${count} -lt 5 ]; do sleep ${SLEEP_SECONDS} && if wget --no-verbose --spider ${DEST_URI}; then count=$((count+1)); echo 'Success ${count}/5'; else count=0; echo 'Failed, retrying...'; fi; done"]
