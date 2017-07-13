import ConfigParser
import json
import os
import requests
import sys
import uuid

conf_dir = sys.argv[1]
manager_ip = sys.argv[2]
manager_port = sys.argv[3]
starting_cap = sys.argv[4]

config = ConfigParser.RawConfigParser()
manager_config = ConfigParser.RawConfigParser()

__file__ = os.path.join(conf_dir, 'client_bigsea.cfg')
manager_config_file = os.path.join(conf_dir, 'manager.cfg')

config.read(__file__)
manager_config.read(manager_config_file)

plugin = manager_config.get('manager', 'plugin')
cluster_size = manager_config.getint('manager', 'cluster_size')
flavor_id = manager_config.get('manager', 'flavor_id')
image_id = manager_config.get('manager', 'image_id')
bigsea_username = manager_config.get('manager', 'bigsea_username')
bigsea_password = manager_config.get('manager', 'bigsea_password')

opportunistic = config.get('plugin', 'opportunistic')
args = config.get('plugin', 'args').split()
args[2] = args[2] + str(uuid.uuid4())[0:5]
main_class = config.get('plugin', 'main_class')
job_template_name = config.get('plugin', 'job_template_name')
job_binary_name = config.get('plugin', 'job_binary_name')
job_binary_url = config.get('plugin', 'job_binary_url')
input_ds_id = ''
output_ds_id = ''
plugin_app = config.get('plugin', 'plugin_app')
expected_time = config.getint('plugin', 'expected_time')
collect_period = config.getint('plugin', 'collect_period')
openstack_plugin = config.get('plugin', 'openstack_plugin')
job_type = config.get('plugin', 'job_type')
version = '1.6.0'
cluster_id = config.get('plugin', 'cluster_id')
slave_ng = config.get('plugin', 'slave_ng')
master_ng = config.get('plugin', 'master_ng')
net_id = config.get('plugin', 'net_id')
actuator = config.get('scaler', 'actuator')
#starting_cap = config.get('scaler', 'starting_cap')

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
    scaling_parameters=scaling_parameters, cluster_size=cluster_size,
    starting_cap=starting_cap, actuator=actuator,
    flavor_id=flavor_id, image_id=image_id, opportunistic=opportunistic,
    args=args, main_class=main_class, job_template_name=job_template_name,
    job_binary_name=job_binary_name, job_binary_url=job_binary_url,
    input_ds_id=input_ds_id, output_ds_id=output_ds_id, 
    plugin_app=plugin_app, expected_time=expected_time, 
    collect_period=collect_period, bigsea_username=bigsea_username,
    bigsea_password=bigsea_password, openstack_plugin=openstack_plugin,
    job_type=job_type, version=version, slave_ng=slave_ng, 
    master_ng=master_ng, net_id=net_id
    )

url = "http://%s:%s/manager/execute" % (manager_ip, manager_port)
body_log = body.copy()
r = requests.post(url, headers=headers, data=json.dumps(body))
print str(r.content).strip()