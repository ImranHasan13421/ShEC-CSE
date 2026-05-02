FROM python:3.10

RUN apt-get update && apt-get install -y \
    chromium \
    chromium-driver \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . .

RUN pip install fastapi uvicorn selenium

ENV CHROME_BIN=/usr/bin/chromium
ENV CHROMEDRIVER_PATH=/usr/bin/chromedriver

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "7860"]