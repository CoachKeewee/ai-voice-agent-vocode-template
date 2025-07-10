# Use official Python 3.9 Debian Bullseye base image
FROM python:3.9-bullseye

# Force APT to use IPv4 to avoid Debian mirror IPv6 network errors
RUN echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4

# Install system dependencies required for audio, ffmpeg, and building Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    libportaudio2 \
    libportaudiocpp0 \
    portaudio19-dev \
    libasound-dev \
    libsndfile1-dev \
    ffmpeg \
    build-essential \
    gcc \
    python3-dev \
    libffi-dev \
    libssl-dev \
    curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /code

# Copy dependency specification files first for better Docker layer caching
COPY pyproject.toml poetry.lock ./

# Install latest Poetry version
RUN pip install --no-cache-dir --upgrade poetry

# Disable Poetry virtual environments to install packages system-wide in container
RUN poetry config virtualenvs.create false

# Install Python dependencies with verbose output to help debugging install issues
RUN poetry install --no-dev --no-interaction --no-ansi -vvv

# Install httpx separately (if needed by your app)
RUN pip install httpx

# Copy application source code and related files
COPY main.py speller_agent.py memory_config.py events_manager.py config.py instructions.txt ./
COPY utils ./utils

# Create folders used at runtime
RUN mkdir -p call_transcripts db

# Start the FastAPI server using uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "3000"]
