FROM nginx:alpine

COPY nginx.conf /etc/nginx/nginx.conf

# Criar diretório para certificados
RUN mkdir -p /etc/nginx/certs

# Copiar certificados
COPY certs/cert.pem /etc/nginx/certs/
COPY certs/key.pem /etc/nginx/certs/

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
