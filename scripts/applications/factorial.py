from flask import Flask
from flask import request
import math

app = Flask(__name__)

@app.route('/run/<n>', methods = ['GET'])
def run(n):
    return str(math.factorial(int(n))),200

if __name__ == '__main__':
   app.run(host='0.0.0.0')
