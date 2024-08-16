FROM python:3.8-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Set the environment variable for the database URL
ENV DATABASE_URL="postgresql://user:password@host.docker.internal:5432/db"
ENV PRODUCT_SERVICE_URL = "host.docker.internal:81"

CMD ["python", "app.py"]
