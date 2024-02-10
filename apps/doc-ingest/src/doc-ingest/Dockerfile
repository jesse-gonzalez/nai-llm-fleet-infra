FROM mcr.microsoft.com/vscode/devcontainers/python:3.11

ENV PYTHONUNBUFFERED True

ENV APP_HOME /app

USER 1001

WORKDIR $APP_HOME

COPY . ./

USER 0

#RUN pip install --no-cache-dir -r requirements.txt

ENV TRANSFORMERS_CACHE /app/model 

RUN pip install --no-cache-dir -r requirements.txt

RUN python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('sentence-transformers/all-mpnet-base-v2', cache_folder='/app/model')"

RUN python -c "import transformers; transformers.utils.move_cache()"

USER 1001


# Set the default command for the resulting image
CMD python -m parliament .
