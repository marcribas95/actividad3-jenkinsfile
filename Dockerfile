FROM python:3.6-slim

# Crear estructura de directorios
RUN mkdir -p /app/tests-reports

WORKDIR /app

# Instalar dependencias
COPY requirements.txt ./
RUN pip install -r requirements.txt

# Copiar código de la aplicación
COPY app ./app

# Copiar tests
COPY tests ./tests

EXPOSE 5000
