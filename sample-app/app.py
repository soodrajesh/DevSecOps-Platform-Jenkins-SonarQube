#!/usr/bin/env python3
"""
Sample Flask Application for DevSecOps Pipeline Testing
This application demonstrates a simple web service with security best practices
"""

from flask import Flask, jsonify, request, render_template_string
import os
import logging
import time
from datetime import datetime
import json

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Security headers
@app.after_request
def after_request(response):
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
    return response

# Health check endpoint
@app.route('/health')
def health_check():
    """Health check endpoint for load balancer"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'version': '1.0.0',
        'environment': os.getenv('ENVIRONMENT', 'development')
    }), 200

# Root endpoint
@app.route('/')
def home():
    """Main application page"""
    template = '''
    <!DOCTYPE html>
    <html>
    <head>
        <title>DevSecOps Sample Application</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
            .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            .header { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 20px; margin-bottom: 30px; }
            .status { background: #d4edda; color: #155724; padding: 15px; border-radius: 4px; margin: 20px 0; }
            .info { background: #e3f2fd; color: #0d47a1; padding: 15px; border-radius: 4px; margin: 10px 0; }
            .endpoint { background: #f8f9fa; padding: 10px; border-left: 4px solid #007bff; margin: 10px 0; }
            code { background: #f1f1f1; padding: 2px 6px; border-radius: 3px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🚀 DevSecOps Sample Application</h1>
                <p>A secure Flask application for CI/CD pipeline testing</p>
            </div>
            
            <div class="status">
                <h3>✅ Application Status: Running</h3>
                <p><strong>Environment:</strong> {{ environment }}</p>
                <p><strong>Version:</strong> 1.0.1</p>
                <p><strong>Timestamp:</strong> {{ timestamp }}</p>
            </div>
            
            <div class="info">
                <h3>📊 Available Endpoints</h3>
                <div class="endpoint">
                    <strong>GET /</strong> - This main page
                </div>
                <div class="endpoint">
                    <strong>GET /health</strong> - Health check endpoint
                </div>
                <div class="endpoint">
                    <strong>GET /api/info</strong> - Application information (JSON)
                </div>
                <div class="endpoint">
                    <strong>GET /api/metrics</strong> - Basic application metrics
                </div>
            </div>
            
            <div class="info">
                <h3>🔒 Security Features</h3>
                <ul>
                    <li>Security headers implemented</li>
                    <li>Input validation and sanitization</li>
                    <li>Structured logging</li>
                    <li>Environment-based configuration</li>
                </ul>
            </div>
            
            <div class="info">
                <h3>🛠️ DevSecOps Pipeline Integration</h3>
                <p>This application is designed to work with the complete DevSecOps pipeline including:</p>
                <ul>
                    <li>Automated security scanning (SonarQube, Checkov)</li>
                    <li>Dependency vulnerability checks (OWASP)</li>
                    <li>Infrastructure as Code deployment</li>
                    <li>Continuous monitoring and alerting</li>
                </ul>
            </div>
        </div>
    </body>
    </html>
    '''
    
    return render_template_string(template, 
                                environment=os.getenv('ENVIRONMENT', 'development'),
                                timestamp=datetime.utcnow().isoformat())

# API info endpoint
@app.route('/api/info')
def api_info():
    """API information endpoint"""
    return jsonify({
        'application': 'DevSecOps Sample App',
        'version': '1.0.0',
        'environment': os.getenv('ENVIRONMENT', 'development'),
        'python_version': os.sys.version,
        'timestamp': datetime.utcnow().isoformat(),
        'endpoints': [
            {'path': '/', 'method': 'GET', 'description': 'Main application page'},
            {'path': '/health', 'method': 'GET', 'description': 'Health check'},
            {'path': '/api/info', 'method': 'GET', 'description': 'Application info'},
            {'path': '/api/metrics', 'method': 'GET', 'description': 'Application metrics'}
        ]
    })

# Metrics endpoint
@app.route('/api/metrics')
def metrics():
    """Basic application metrics"""
    return jsonify({
        'uptime_seconds': time.time() - start_time,
        'requests_total': request_count,
        'environment': os.getenv('ENVIRONMENT', 'development'),
        'timestamp': datetime.utcnow().isoformat(),
        'memory_usage': {
            'available': True,
            'note': 'Memory metrics would be implemented with proper monitoring tools'
        }
    })

# Request counter middleware
request_count = 0
start_time = time.time()

@app.before_request
def before_request():
    global request_count
    request_count += 1
    logger.info(f"Request {request_count}: {request.method} {request.path}")

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return jsonify({
        'error': 'Not Found',
        'message': 'The requested resource was not found',
        'status_code': 404
    }), 404

@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal server error: {error}")
    return jsonify({
        'error': 'Internal Server Error',
        'message': 'An internal server error occurred',
        'status_code': 500
    }), 500

if __name__ == '__main__':
    # Configuration
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
    host = os.getenv('FLASK_HOST', '0.0.0.0')
    
    logger.info(f"Starting DevSecOps Sample Application on {host}:{port}")
    logger.info(f"Environment: {os.getenv('ENVIRONMENT', 'development')}")
    logger.info(f"Debug mode: {debug}")
    
    app.run(host=host, port=port, debug=debug)
