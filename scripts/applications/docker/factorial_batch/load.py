from flask import Flask
from flask import request

workload_file = open("workload.txt", "r")
workload = workload_file.readlines()

app = Flask(__name__)

@app.route('/input', methods = ['GET'])
def load_input():
    if len(workload) > 0:
        return (workload.pop()).strip(),200
    else:
        return "-1",200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=10000)
