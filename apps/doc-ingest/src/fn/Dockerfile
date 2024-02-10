FROM mcr.microsoft.com/vscode/devcontainers/python:3.11

ENV PYTHONUNBUFFERED True

ENV APP_HOME /app

USER 1001

WORKDIR $APP_HOME
COPY . ./

USER 0

RUN pip install --no-cache-dir -r requirements.txt

USER 1001

# Set the default command for the resulting image
CMD python -m parliament .