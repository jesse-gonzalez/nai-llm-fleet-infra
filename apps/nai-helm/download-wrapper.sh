#!/bin/bash

modelarg=$1
output=$2

# split parameters from URI 'ntnx://'
string=${modelarg#ntnx://}
MODEL_NAME=$(echo "$string" | awk -F'/' '{print $1}')
MODEL_REVISION=$(echo "$string" | awk -F'/' '{print $2}')
echo "Model Name: $MODEL_NAME"
echo "Model Revision: $MODEL_REVISION"

if [ -z "$MODEL_REVISION" ]; then
    echo "no revision configured, using default value from model_config.json"
    python3 llm/generate.py --model_name $MODEL_NAME --output $output
    MODEL_REVISION=$(jq -r --arg model "$MODEL_NAME" '.[$model].repo_version' llm/model_config.json)
    echo "Model Revision: $MODEL_REVISION"
else
    python3 llm/generate.py --repo_version=$MODEL_REVISION --model_name $MODEL_NAME --output $output

fi
python3 llm/generate.py --model_name $MODEL_NAME --output $output

ln -s /mnt/models/$MODEL_NAME/$MODEL_REVISION/config /mnt/models/config
ln -s /mnt/models/$MODEL_NAME/$MODEL_REVISION/model-store /mnt/models/model-store
