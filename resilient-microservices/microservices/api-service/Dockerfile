FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# Copiar certificados TLS
COPY certs/cert.pem cert.pem
COPY certs/key.pem key.pem

# Hardening
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app
USER appuser

EXPOSE 5000

CMD ["python", "app.py"]
