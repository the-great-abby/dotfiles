FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY mcp/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY mcp/ /app/
COPY zsh/ /app/zsh/

# Create data directories
RUN mkdir -p /data/gtd/suggestions \
    /data/gtd/deep_analysis_results \
    /data/daily_logs \
    /data/second_brain

# Set working directory
WORKDIR /app

# Default command (can be overridden)
CMD ["python3", "gtd_deep_analysis_worker.py"]

