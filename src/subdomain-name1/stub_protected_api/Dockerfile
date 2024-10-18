FROM python:3.13.0-bookworm

WORKDIR /app

COPY . /app

# hadolint ignore=DL3013
RUN pip install --no-cache-dir fastapi gunicorn uvicorn

EXPOSE 8000

CMD ["gunicorn", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "app:app", "--bind", "0.0.0.0:8000", "--timeout", "120"]
