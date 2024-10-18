FROM python:3.13.0-bookworm

ENV DEST_DOMAIN="stub-intra-api"
ENV DEST_PORT="8000"
ENV SLEEP_FOR="5"
ENV DEST_URI="http://${DEST_DOMAIN}:${DEST_PORT}"

CMD [ "sh", "-c", "count=0; \
  while [ \"${count}\" -lt 5 ]; do \
  if wget --no-verbose --spider \"${DEST_URI}\"; then \
  count=$((count+1)); \
  echo \"Success ${count}/5\"; \
  echo \"Sleeping for ${SLEEP_FOR} seconds\"; \
  sleep \"${SLEEP_FOR}\"; \
  else \
  count=0; \
  echo \"Failed, retrying...\"; \
  fi; \
  done" ]
