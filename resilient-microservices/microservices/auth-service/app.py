from flask import Flask, jsonify, request
import requests
import jwt
import os
import hashlib
from datetime import datetime, timedelta

app = Flask(__name__)
LOGGER_URL = os.getenv('LOGGER_URL', 'http://logger-service:5000')
SERVICE_NAME = 'auth-service'
SECRET_KEY = os.getenv('JWT_SECRET', 'supersecretkey123')

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

@app.route('/auth/login', methods=['POST'])
def login():
    client_ip = request.headers.get('X-Real-IP', request.remote_addr)
    data = request.get_json() or {}
    username = data.get('username', '')
    password = data.get('password', '')
    
    send_log('INFO', 'Login attempt', {'username': username, 'client': client_ip})
    
    # Autenticação simples (demo)
    if username and password:
        token = jwt.encode({
            'user': username,
            'exp': datetime.utcnow() + timedelta(hours=1)
        }, SECRET_KEY, algorithm='HS256')
        
        send_log('INFO', 'Login successful', {'username': username})
        return jsonify({'token': token, 'status': 'authenticated'}), 200
    
    send_log('WARNING', 'Login failed', {'username': username})
    return jsonify({'error': 'Invalid credentials'}), 401

@app.route('/auth/verify', methods=['POST'])
def verify():
    data = request.get_json() or {}
    token = data.get('token', '')
    
    try:
        decoded = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
        send_log('INFO', 'Token verified', {'user': decoded.get('user')})
        return jsonify({'valid': True, 'user': decoded.get('user')}), 200
    except:
        send_log('WARNING', 'Invalid token')
        return jsonify({'valid': False}), 401

if __name__ == '__main__':
    send_log('INFO', 'Service starting')
    app.run(host='0.0.0.0', port=5000, ssl_context=('cert.pem', 'key.pem'))
