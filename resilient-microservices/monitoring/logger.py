from flask import Flask, request, jsonify
import json
import os
from datetime import datetime
from pathlib import Path

app = Flask(__name__)

LOGS_DIR = '/logs'
LOGS_FILE = os.path.join(LOGS_DIR, 'centralized.json')

# Criar diretório de logs
Path(LOGS_DIR).mkdir(parents=True, exist_ok=True)

def write_log(log_entry):
    try:
        # Ler logs existentes
        if os.path.exists(LOGS_FILE):
            with open(LOGS_FILE, 'r') as f:
                logs = json.load(f)
        else:
            logs = []
        
        # Adicionar novo log
        logs.append(log_entry)
        
        # Manter apenas últimos 10000 logs
        if len(logs) > 10000:
            logs = logs[-10000:]
        
        # Escrever de volta
        with open(LOGS_FILE, 'w') as f:
            json.dump(logs, f, indent=2)
        
        return True
    except Exception as e:
        print(f"Error writing log: {e}")
        return False

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy', 'service': 'logger-service'}), 200

@app.route('/log', methods=['POST'])
def receive_log():
    log_data = request.get_json()
    if log_data:
        write_log(log_data)
    return jsonify({'status': 'logged'}), 200

@app.route('/logs', methods=['GET'])
def get_logs():
    try:
        if os.path.exists(LOGS_FILE):
            with open(LOGS_FILE, 'r') as f:
                logs = json.load(f)
            
            # Filtros opcionais
            service = request.args.get('service')
            level = request.args.get('level')
            limit = int(request.args.get('limit', 100))
            
            filtered = logs
            if service:
                filtered = [l for l in filtered if l.get('service') == service]
            if level:
                filtered = [l for l in filtered if l.get('level') == level]
            
            return jsonify(filtered[-limit:]), 200
        else:
            return jsonify([]), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/stats', methods=['GET'])
def get_stats():
    try:
        if os.path.exists(LOGS_FILE):
            with open(LOGS_FILE, 'r') as f:
                logs = json.load(f)
            
            stats = {
                'total_logs': len(logs),
                'by_service': {},
                'by_level': {},
                'last_log': logs[-1] if logs else None
            }
            
            for log in logs:
                service = log.get('service', 'unknown')
                level = log.get('level', 'unknown')
                stats['by_service'][service] = stats['by_service'].get(service, 0) + 1
                stats['by_level'][level] = stats['by_level'].get(level, 0) + 1
            
            return jsonify(stats), 200
        else:
            return jsonify({'total_logs': 0}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    print(f"Logger service starting. Logs will be stored in {LOGS_FILE}")
    app.run(host='0.0.0.0', port=5000)
