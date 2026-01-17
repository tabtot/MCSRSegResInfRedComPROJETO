FROM python:3.9-slim

WORKDIR /app

RUN pip install --no-cache-dir Flask==2.3.0

COPY logger.py .

# Criar diretório de logs
RUN mkdir -p /logs && chmod 777 /logs

# Hardening
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app /logs
USER appuser

EXPOSE 5000

CMD ["python", "logger.py"]
