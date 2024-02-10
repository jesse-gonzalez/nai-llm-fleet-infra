from flask import Flask, render_template, request, jsonify, redirect
import requests
import argparse
import json
import logging

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

def get_default_model_name(inference_host):
    kserve_url = f'http://{inference_host}/v1/models'
    torchserve_url = f'http://{inference_host}:8081/models'
    
    try:
        response = requests.get(kserve_url)
        response.raise_for_status()
        models = response.json()
        args.use_k8s = True
        logging.info("Connected to kserve.")
        return models['models'][0]
    except requests.exceptions.RequestException as e:
        logging.error(f"Failed to connect to kserve at {kserve_url}: {e}")

    try:
        response = requests.get(torchserve_url)
        response.raise_for_status()
        models = response.json()
        args.use_k8s = False
        logging.info("Connected to TorchServe.")
        return models['models'][0]['modelName']
    except requests.exceptions.RequestException as e:
        logging.error(f"Failed to connect to TorchServe at {torchserve_url}: {e}")

    logging.error("Failed to fetch the default model name from both kserve and TorchServe.")
    return None

@app.route('/')
def index():
    if args.inference_host is None or args.model_name is None:
        return redirect('/connect')
    return render_template('index.html')

@app.route('/connect', methods=['GET'])
def connect_form():
    return render_template('connect.html')

@app.route('/connect', methods=['POST'])
def connect():
    try:
        new_host = request.json.get('inference_host')
        if new_host:
            logging.info(f"Attempting to connect to new inference host: {new_host}")
            args.inference_host = new_host
            args.model_name = get_default_model_name(new_host)
            if args.model_name is None:
                raise Exception("Failed to get the default model name from the new inference host")
            return jsonify({'message': f'Successfully connected to {new_host} with model {args.model_name}'})
        else:
            logging.error("No inference host provided in the request")
            return jsonify({'error': 'No inference host provided'}), 400
    except Exception as e:
        logging.error(f"Failed to connect to the new inference host: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/ask', methods=['POST'])
def ask():
    if args.inference_host is None or args.model_name is None:
        return jsonify({'error': 'Please set the inference host and model name via /connect first'}), 400

    user_message = request.form.get('user_message')
    if not user_message:
        logging.warning("Empty user message received")
        return jsonify({'error': 'User message cannot be empty'}), 400

    try:

        if args.use_k8s:
            model_endpoint = f'http://{args.inference_host}/v2/models/{args.model_name}/infer'
            payload = {
                "id": "1",
                "inputs": [
                    {
                        "name": "input0",
                        "shape": [-1],
                        "datatype": "BYTES",
                        "data": [user_message]
                    }
                ]
            }
            response = requests.post(model_endpoint, json=payload)
            result = response.json()
            reply = result['outputs'][0]['data']
            return jsonify({'model_response': reply})
        else:
            model_endpoint = f'http://{args.inference_host}:8080/predictions/{args.model_name}'
            response = requests.post(model_endpoint, data=user_message)
            if response.status_code == 200:
                return jsonify({'model_response': response.text})
            else:
                return jsonify({'model_response': 'Failed to get response from the model'})
    except Exception as e:
        logging.error(f"An error occurred while communicating with the model: {e}")
        return jsonify({'error': 'Failed to get response from the model'}), 500

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Chat Client for Inference Services')
    parser.add_argument('--model-name', default=None)
    parser.add_argument('--inference-host', default=None)
    parser.add_argument('--use-k8s', default=False, action='store_true')
    args = parser.parse_args()

    app.run(debug=True, host='0.0.0.0', port=8000)