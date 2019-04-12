#!/usr/bin/python

import sys
from flask import Flask
from flask import request

class Controller:

	def __init__(self, proportional_gain, derivative_gain, integral_gain):
		self.proportional_gain = proportional_gain
		self.derivative_gain = derivative_gain
		self.integral_gain = integral_gain
		self.last_error = 0
		self.sum_error = 0

	def decide_action(self, error):
		proportional_component = self.proportional_gain * error
		derivative_component = self.derivative_gain * (error - self.last_error)
		self.last_error = error

		self.sum_error += error
		integral_component = self.integral_gain * self.sum_error

		return -1 * (proportional_component + derivative_component + integral_component)

app = Flask(__name__)

@app.route('/action/<error>', methods = ['GET'])
def action(error):
    return str(controller.decide_action(float(error))),200

if __name__ == '__main__':

	proportional_gain = float(sys.argv[1])
	derivative_gain = float(sys.argv[2])
	integral_gain = float(sys.argv[3])

	controller = Controller(proportional_gain, derivative_gain, integral_gain)
	
	app.run(host='0.0.0.0', port=5002)

