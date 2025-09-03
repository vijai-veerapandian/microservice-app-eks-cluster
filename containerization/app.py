from flask import Flask, jsonify
import datetime

app = Flask(__name__)

@app.route('/')
def home():
    """Default route to check if the API is running."""
    return "API is running!"

@app.route('/api/v1/status')
def get_status():
    """A simple API endpoint that returns a JSON response."""
    response = {
        'status': 'ok',
        'timestamp': datetime.datetime.utcnow().isoformat()
    }
    return jsonify(response)

if __name__ == '__main__':
    # Run the app on port 5000, accessible from other containers
    app.run(host='0.0.0.0', port=5000)