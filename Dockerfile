FROM python:3.9-bullseye

# Force APT to use IPv4 to avoid Debian IPv6 network issues
RUN echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4

# Update and install required system packages in a single layer
RUN apt-get update && \
    apt-get install -y \
        libportaudio2 \
        libportaudiocpp0 \
        portaudio19-dev \
        libasound-dev \
        libsndfile1-dev \
        ffmpeg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /code

# Copy dependency files first for layer caching
COPY ./pyproject.toml ./poetry.lock ./

# Install Poetry and dependencies
RUN pip install --no-cache-dir --upgrade poetry && \
    poetry config virtualenvs.create false && \
    poetry install --no-dev --no-interaction --no-ansi

# Install direct non-poetry deps
RUN pip install httpx

# Copy application code
COPY main.py speller_agent.py memory_config.py events_manager.py config.py instructions.txt ./
COPY ./utils ./utils

# Create persistent directories
RUN mkdir -p /code/call_transcripts /code/db

# Run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "3000"]
