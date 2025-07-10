FROM python:3.9-bullseye

# Force APT to use IPv4 to avoid network errors with Debian mirrors
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

# Copy Poetry dependency files first for better Docker layer caching
COPY pyproject.toml poetry.lock ./

# Install latest Poetry version
RUN pip install --no-cache-dir --upgrade poetry

# Disable Poetry virtual environments to install packages system-wide
RUN poetry config virtualenvs.create false

# Install Python dependencies (no --without or --no-dev flags since no dev dependencies defined)
RUN poetry install --no-interaction --no-ansi -vvv > poetry_install.log 2>&1 || (cat poetry_install.log && false)

# Install httpx if needed
RUN pip install httpx

# Copy application source code and related files
COPY main.py speller_agent.py memory_config.py events_manager.py config.py instructions.txt ./
COPY utils ./utils

# Create runtime directories
RUN mkdir -p call_transcripts db

# Start the FastAPI server using uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "3000"]
