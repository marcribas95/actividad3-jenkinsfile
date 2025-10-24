FROM nginx:alpine

# Copiar archivos estáticos
COPY index.html /usr/share/nginx/html/index.html

# Copiar configuración personalizada de nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
