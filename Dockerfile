FROM python:3.9-bullseye

# Force APT to use IPv4 to avoid network errors
RUN echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4

# Install system dependencies
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

WORKDIR /code

COPY pyproject.toml poetry.lock ./

RUN pip install --no-cache-dir --upgrade poetry

RUN poetry config virtualenvs.create false

# Run poetry install, capture logs to file, print logs if failure occurs
RUN poetry install --no-dev --no-interaction --no-ansi -vvv > poetry_install.log 2>&1 || (cat poetry_install.log && false)

RUN pip install httpx

COPY main.py speller_agent.py memory_config.py events_manager.py config.py instructions.txt ./
COPY utils ./utils

RUN mkdir -p call_transcripts db

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "3000"]
