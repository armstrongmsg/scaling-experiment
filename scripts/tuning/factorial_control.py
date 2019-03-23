from flask import Flask
from flask import request
import math
import threading
import requests
import sys

app = Flask(__name__)

class Factorial_Execution:
    def __init__(self, vm_ip, vm_port):
        self.app_url = "http://%s:%s/run" % (vm_ip, vm_port)
        self.completed_tasks = 0
        self.stop = False
        self.stopped = False

    def start(self, n, number_of_times):
        self.completed_tasks = 0
        self.stop = False
        self.stopped = False
        self.ex = threading.Thread(target=self.calc, args=(n, number_of_times))

        self.ex.start()

    def calc(self, n, number_of_times):
        calc_url = self.app_url + "/" + str(n)
        for i in xrange(number_of_times):
            requests.get(calc_url)
            self.completed_tasks += 1

            if self.stop:
                self.stopped = True
                break

@app.route('/start/<n>/<i>', methods = ['POST'])
def start(n, i):
    ex.start(int(n), int(i))
    return "",200

@app.route('/tasks', methods = ['GET'])
def get_tasks():
    return str(ex.completed_tasks),200

@app.route('/stop', methods = ['POST'])
def stop():
    ex.stop = True
    return "",200

@app.route('/stopped', methods = ['GET'])
def stopped():
    return str(ex.stopped),200

if __name__ == '__main__':
    vm_ip = sys.argv[1]
    vm_port = sys.argv[2]
    ex = Factorial_Execution(vm_ip, vm_port)
    app.run(host='0.0.0.0', port=5001)

