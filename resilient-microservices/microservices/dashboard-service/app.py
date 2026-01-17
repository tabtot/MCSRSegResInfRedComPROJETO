from flask import Flask, jsonify, request
import requests
import os
from datetime import datetime

app = Flask(__name__)
LOGGER_URL = os.getenv('LOGGER_URL', 'http://logger-service:5000')
SERVICE_NAME = 'dashboard-service'

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

HTML_TEMPLATE = '''
    
    <!DOCTYPE html>
    <head>
    <title>Dashboard - Resilient Microservices</title>
    </head>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 40px; 
            background: #f5f5f5; 
        }
        .container { 
            background: white; 
            padding: 20px; 
            border-radius: 8px; 
            max-width: 800px; 
            margin: 0 auto;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 { 
            color: #333; 
            border-bottom: 3px solid #2196f3;
            padding-bottom: 10px;
        }
        .status { 
            padding: 15px; 
            margin: 20px 0; 
            background: #e8f5e9; 
            border-left: 4px solid #4caf50;
            border-radius: 4px;
        }
        .status-item {
            margin: 5px 0;
        }
        .status-label {
            font-weight: bold;
            display: inline-block;
            width: 120px;
        }
        h2 {
            color: #555;
            margin-top: 30px;
        }
        .metrics {
            display: flex;
            flex-wrap: wrap;
            gap: 20px;
        }
        .metric { 
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            min-width: 150px;
            text-align: center;
            border: 2px solid #e0e0e0;
        }
        .metric-value { 
            font-size: 32px; 
            font-weight: bold; 
            color: #2196f3;
            display: block;
            margin-bottom: 5px;
        }
        .metric-label { 
            font-size: 14px; 
            color: #666;
            display: block;
        }
    </style>
    <body>

    <h1>🛡️ Dashboard de Resiliência</h1>
    <h2>Status:Sistema Operacional</h2>
    <p>     
            
                Timestamp:
                {{ timestamp }}
            
            
                Pod:
                {{ pod }}
            
     </p>   
    <p>
        Métricas do Sistema
        
            
                3
                Microserviços
            
            
                3
                Réplicas/Serviço
    </p>
    </body>
    </html>

    


    
            
        
    

'''

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy', 'service': SERVICE_NAME}), 200

@app.route('/ready', methods=['GET'])
def ready():
    return jsonify({'status': 'ready', 'service': SERVICE_NAME}), 200

@app.route('/', methods=['GET'])
def dashboard():
    client_ip = request.headers.get('X-Real-IP', request.remote_addr)
    send_log('INFO', 'Dashboard accessed', {'client': client_ip})
    
    html = HTML_TEMPLATE.replace('{{ timestamp }}', datetime.utcnow().isoformat())
    html = html.replace('{{ pod }}', os.getenv('HOSTNAME', 'unknown'))
    
    return html, 200, {'Content-Type': 'text/html; charset=utf-8'}

@app.route('/metrics', methods=['GET'])
def metrics():
    metrics_data = {
        'service': SERVICE_NAME,
        'timestamp': datetime.utcnow().isoformat(),
        'metrics': {
            'total_services': 3,
            'replicas_per_service': 3,
            'availability': '100%',
            'rto_target': '< 30s',
            'mttr_target': '< 60s'
        }
    }
    return jsonify(metrics_data), 200

if __name__ == '__main__':
    send_log('INFO', 'Service starting')
    app.run(host='0.0.0.0', port=5000, ssl_context=('cert.pem', 'key.pem'))
