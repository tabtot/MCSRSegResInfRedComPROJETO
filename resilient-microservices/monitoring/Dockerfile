FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY logger.py .

# Criar utilizador antes de criar diretório
RUN useradd -m -u 1000 appuser

# Criar diretório de logs e dar permissões completas
RUN mkdir -p /logs && \
    chown -R appuser:appuser /app /logs && \
    chmod -R 755 /app && \
    chmod -R 777 /logs

# Mudar para appuser
USER appuser

EXPOSE 5000

CMD ["python", "logger.py"]
