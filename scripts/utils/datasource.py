from flask import Flask
from flask import request
import math

app = Flask(__name__)

@app.route('/jobs/<filename>', methods = ['GET'])
def jobs(filename):
    f = open(filename, "r")
    jobs_lines = f.readlines()

    content = ""
    for line in jobs_lines:
        content += line

    f.close()
    return content,200

if __name__ == '__main__':
   app.run(host='0.0.0.0', port=3456)
