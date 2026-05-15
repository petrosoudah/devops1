FROM python:3.11-slim

ARG APP_ARTIFACT

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# the image is built from the pipeline artifact, not directly from repo files
COPY ${APP_ARTIFACT} /tmp/app.tar.gz
RUN tar -xzf /tmp/app.tar.gz -C /app \
    && rm /tmp/app.tar.gz \
    && if [ -f requirements.lock ]; then pip install --no-cache-dir -r requirements.lock; else pip install --no-cache-dir -r requirements.txt; fi

EXPOSE 8000

CMD ["gunicorn", "book_shop.wsgi:application", "--bind", "0.0.0.0:8000"]
