FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN pip install --no-cache-dir Flask==3.1.1 \
    && groupadd --system app \
    && useradd --system --gid app --no-create-home app

COPY app.py .

USER app
EXPOSE 5000
CMD ["python", "app.py"]
