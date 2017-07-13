import ConfigParser
import json
import os
import requests
import sys

conf_dir = sys.argv[1]
manager_ip = sys.argv[2]
manager_port = sys.argv[3]
starting_cap = sys.argv[4]

config = ConfigParser.RawConfigParser()
manager_config = ConfigParser.RawConfigParser()

print conf_dir
__file__ = os.path.join(conf_dir, 'client_bigsea.cfg')
manager_config_file = os.path.join(conf_dir, 'manager.cfg')

print __file__

config.read(__file__)
manager_config.read(manager_config_file)

bigsea_username = manager_config.get('manager', 'bigsea_username')
bigsea_password = manager_config.get('manager', 'bigsea_password')
plugin = manager_config.get('manager', 'plugin')
cluster_size = manager_config.getint('manager', 'cluster_size')
flavor_id = manager_config.get('manager', 'flavor_id')
image_id = manager_config.get('manager', 'image_id')

command = config.get('plugin', 'command')
reference_value = config.getfloat('plugin', 'reference_value')
log_path = config.get('plugin', 'log_path')

scaler_plugin = config.get('scaler', 'scaler_plugin')

scaling_parameters = {}

if scaler_plugin == 'progress-error' or scaler_plugin == 'progress-tendency':	
	actuator = config.get('scaler', 'actuator')
	metric_source = config.get('scaler', 'metric_source')
	check_interval = config.getint('scaler', 'check_interval')
	trigger_down = config.getint('scaler', 'trigger_down')
	trigger_up = config.getint('scaler', 'trigger_up')
	min_cap = config.getint('scaler', 'min_cap')
	max_cap = config.getint('scaler', 'max_cap')
	actuation_size = config.getint('scaler', 'actuation_size')
	metric_rounding = config.getint('scaler', 'metric_rounding')

	scaling_parameters = {'check_interval':check_interval,
					'trigger_down':trigger_down, 'trigger_up':trigger_up,
					'min_cap':min_cap, 'max_cap':max_cap,
					'actuation_size':actuation_size, 'metric_rounding':metric_rounding, 
					'actuator':actuator, 'metric_source':metric_source}
	
elif scaler_plugin == 'proportional':
	actuator = config.get('scaler', 'actuator')
	metric_source = config.get('scaler', 'metric_source')
	check_interval = config.getint('scaler', 'check_interval')
	trigger_down = config.getint('scaler', 'trigger_down')
	trigger_up = config.getint('scaler', 'trigger_up')
	min_cap = config.getint('scaler', 'min_cap')
	max_cap = config.getint('scaler', 'max_cap')
	metric_rounding = config.getint('scaler', 'metric_rounding')
	heuristic_name = config.get('scaler', 'heuristic_name')
	
	heuristic_options = {}
	heuristic_options['heuristic_name'] = heuristic_name
	
	if heuristic_name == "error_proportional":
		conservative_factor = config.getfloat('scaler', 'conservative_factor')
		heuristic_options['conservative_factor'] = conservative_factor

	scaling_parameters = {'check_interval':check_interval,
					'trigger_down':trigger_down, 'trigger_up':trigger_up,
					'min_cap':min_cap, 'max_cap':max_cap, 'metric_rounding':metric_rounding, 
					'actuator':actuator, 'metric_source':metric_source, 'heuristic_options': heuristic_options}

headers = {'Content-Type': 'application/json'}
body = dict(plugin=plugin, scaler_plugin=scaler_plugin,
	scaling_parameters=scaling_parameters, actuator=actuator, cluster_size=cluster_size,
	starting_cap=starting_cap, flavor_id=flavor_id, image_id=image_id, command=command,
	reference_value=reference_value, log_path=log_path, bigsea_username=bigsea_username, 
	bigsea_password=bigsea_password)

url = "http://%s:%s/manager/execute" % (manager_ip, manager_port)
body_log = body.copy()
r = requests.post(url, headers=headers, data=json.dumps(body))
print r.content
