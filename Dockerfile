FROM python:3.6-slim

# Establecer directorio de trabajo
WORKDIR /opt/calc

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements y instalar dependencias Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# El código se montará como volumen, no se copia aquí
# Esto permite desarrollo en vivo y testing

EXPOSE 5000

# Comando por defecto (puede ser sobrescrito)
CMD ["python", "-B", "app/calc.py"]
