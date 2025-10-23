FROM python:3.6-slim

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Crear estructura de directorios
RUN mkdir -p /app/tests-reports

# Establecer directorio de trabajo
WORKDIR /app

# Copiar requirements y instalar dependencias Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código de la aplicación
COPY app ./app

# Copiar tests
COPY tests ./tests

# Copiar web (para tener todo disponible)
COPY web ./web

# Exponer puerto Flask
EXPOSE 5000

# Comando por defecto
CMD ["python", "-m", "flask", "run", "--host=0.0.0.0"]