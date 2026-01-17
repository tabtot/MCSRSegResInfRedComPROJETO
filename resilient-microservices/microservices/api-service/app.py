from flask import Flask, jsonify, request
import requests
import time
import os
import json
from datetime import datetime

app = Flask(__name__)
LOGGER_URL = os.getenv('LOGGER_URL', 'http://logger-service:5000')
SERVICE_NAME = 'api-service'

def send_log(level, message, extra=None):
    try:
        log_data = {
            'timestamp': datetime.utcnow().isoformat(),
            'service': SERVICE_NAME,
            'level': level,
            'message': message,
            'pod': os.getenv('HOSTNAME', 'unknown'),
            'extra': extra or {}
        }
        requests.post(f'{LOGGER_URL}/log', json=log_data, timeout=1)
    except:
        pass

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy', 'service': SERVICE_NAME}), 200

@app.route('/ready', methods=['GET'])
def ready():
    return jsonify({'status': 'ready', 'service': SERVICE_NAME}), 200

@app.route('/api/data', methods=['GET'])
def get_data():
    client_ip = request.headers.get('X-Real-IP', request.remote_addr)
    send_log('INFO', 'Data requested', {'endpoint': '/api/data', 'client': client_ip})
    
    data = {
        'service': SERVICE_NAME,
        'timestamp': datetime.utcnow().isoformat(),
        'data': [
            {'id': 1, 'name': 'Item A', 'value': 100},
            {'id': 2, 'name': 'Item B', 'value': 200},
            {'id': 3, 'name': 'Item C', 'value': 300}
        ]
    }
    return jsonify(data), 200

@app.route('/api/process', methods=['POST'])
def process_data():
    client_ip = request.headers.get('X-Real-IP', request.remote_addr)
    payload = request.get_json() or {}
    send_log('INFO', 'Processing data', {'endpoint': '/api/process', 'client': client_ip})
    
    # Simular processamento
    time.sleep(0.1)
    
    result = {
        'service': SERVICE_NAME,
        'status': 'processed',
        'input': payload,
        'result': 'success'
    }
    return jsonify(result), 200

if __name__ == '__main__':
    send_log('INFO', 'Service starting')
    app.run(host='0.0.0.0', port=5000, ssl_context=('cert.pem', 'key.pem'))
