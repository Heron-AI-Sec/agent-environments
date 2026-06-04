# backend/Dockerfile — Flask backend API image for the Attack_me_1 testbed.
# ⚠️ INTENTIONALLY VULNERABLE SOFTWARE — isolated research use only. ⚠️

FROM python:3.12-slim

WORKDIR /app

# Install Python dependencies first to leverage layer caching.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application source.
COPY app.py .

# Backend internal Flask port (DESIGN.md Section 3.3) — internal only, no host publish.
EXPOSE 6000

CMD ["python", "app.py"]
