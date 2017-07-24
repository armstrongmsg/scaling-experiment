import ConfigParser
import json
import os
import requests
import sys
import uuid

class OS_Generic_Plugin:
    
    def run(self):
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


class Sahara_Plugin:
    
    def run(self, scaling_config, manager_config, application_config, manager_ip, manager_port, starting_cap): 
        plugin = application_config.get('application', 'plugin')
        
        cluster_size = manager_config.getint('manager', 'cluster_size')
        flavor_id = manager_config.get('manager', 'flavor_id')
        image_id = manager_config.get('manager', 'image_id')
        bigsea_username = manager_config.get('manager', 'bigsea_username')
        bigsea_password = manager_config.get('manager', 'bigsea_password')
        
        opportunistic = application_config.get('application', 'opportunistic')
        
        main_class = application_config.get('application', 'main_class')
        job_template_name = application_config.get('application', 'job_template_name')
        job_binary_name = application_config.get('application', 'job_binary_name')
        
        args = application_config.get('application', 'args').split()
        
        if job_binary_name == "EMaaS":
            args[2] = args[2] + str(uuid.uuid4())[0:5]
        elif job_binary_name == "KMeans":
            args[1] = args[1] + str(uuid.uuid4())[0:5]
        
        job_binary_url = application_config.get('application', 'job_binary_url')
        input_ds_id = ''
        output_ds_id = ''
        plugin_app = application_config.get('application', 'plugin_app')
        expected_time = application_config.getint('application', 'expected_time')
        collect_period = application_config.getint('application', 'collect_period')
        openstack_plugin = application_config.get('application', 'openstack_plugin')
        job_type = application_config.get('application', 'job_type')
        version = '1.6.0'
        cluster_id = application_config.get('application', 'cluster_id')
        slave_ng = application_config.get('application', 'slave_ng')
        master_ng = application_config.get('application', 'master_ng')
        net_id = application_config.get('application', 'net_id')
        opportunistic_slave_ng = application_config.get('application', 'opportunistic_slave_ng')
        
        actuator = scaling_config.get('scaler', 'actuator')
        scaler_plugin = scaling_config.get('scaler', 'scaler_plugin')
        scaling_parameters = {}
        
        if scaler_plugin == 'progress-error' or scaler_plugin == 'progress-tendency':    
            actuator = scaling_config.get('scaler', 'actuator')
            metric_source = scaling_config.get('scaler', 'metric_source')
            check_interval = scaling_config.getint('scaler', 'check_interval')
            trigger_down = scaling_config.getint('scaler', 'trigger_down')
            trigger_up = scaling_config.getint('scaler', 'trigger_up')
            min_cap = scaling_config.getint('scaler', 'min_cap')
            max_cap = scaling_config.getint('scaler', 'max_cap')
            actuation_size = scaling_config.getint('scaler', 'actuation_size')
            metric_rounding = scaling_config.getint('scaler', 'metric_rounding')
            total_tasks = scaling_config.get('scaler', 'total_tasks')
            spark_master_ip = scaling_config.get('scaler', 'spark_master_ip')
        
            scaling_parameters = {'check_interval':check_interval,
                            'trigger_down':trigger_down, 'trigger_up':trigger_up,
                            'min_cap':min_cap, 'max_cap':max_cap,
                            'actuation_size':actuation_size, 'metric_rounding':metric_rounding, 
                            'actuator':actuator, 'metric_source':metric_source, 
                            'total_tasks':total_tasks, 'spark_master_ip':spark_master_ip, 
                            'expected_time':expected_time}
            
        elif scaler_plugin == 'proportional':
            actuator = scaling_config.get('scaler', 'actuator')
            metric_source = scaling_config.get('scaler', 'metric_source')
            check_interval = scaling_config.getint('scaler', 'check_interval')
            trigger_down = scaling_config.getint('scaler', 'trigger_down')
            trigger_up = scaling_config.getint('scaler', 'trigger_up')
            min_cap = scaling_config.getint('scaler', 'min_cap')
            max_cap = scaling_config.getint('scaler', 'max_cap')
            metric_rounding = scaling_config.getint('scaler', 'metric_rounding')
            heuristic_name = scaling_config.get('scaler', 'heuristic_name')
            total_tasks = scaling_config.get('scaler', 'total_tasks')
            spark_master_ip = scaling_config.get('scaler', 'spark_master_ip')
            
            heuristic_options = {}
            heuristic_options['heuristic_name'] = heuristic_name
            
            if heuristic_name == "error_proportional":
                conservative_factor = scaling_config.getfloat('scaler', 'conservative_factor')
                heuristic_options['conservative_factor'] = conservative_factor
        
            scaling_parameters = {'check_interval':check_interval,
                            'trigger_down':trigger_down, 'trigger_up':trigger_up,
                            'min_cap':min_cap, 'max_cap':max_cap, 'metric_rounding':metric_rounding, 
                            'actuator':actuator, 'metric_source':metric_source, 
                            'heuristic_options': heuristic_options, 'total_tasks':total_tasks,
                            'spark_master_ip':spark_master_ip, 'expected_time':expected_time}
        
        
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
            master_ng=master_ng, net_id=net_id, 
            opportunistic_slave_ng=opportunistic_slave_ng
            )
        
        url = "http://%s:%s/manager/execute" % (manager_ip, manager_port)
        body_log = body.copy()
        r = requests.post(url, headers=headers, data=json.dumps(body))
        print str(r.content).strip()

def main():
    conf_dir = sys.argv[1]
    manager_ip = sys.argv[2]
    manager_port = sys.argv[3]
    starting_cap = sys.argv[4]
    
    scaling_config = ConfigParser.RawConfigParser()
    manager_config = ConfigParser.RawConfigParser()
    application_config = ConfigParser.RawConfigParser()
    
    scaling_config_file = os.path.join(conf_dir, 'scaling.cfg')
    manager_config_file = os.path.join(conf_dir, 'manager.cfg')
    application_config_file = os.path.join(conf_dir, 'application.cfg')
    
    scaling_config.read(scaling_config_file)
    manager_config.read(manager_config_file)
    application_config.read(application_config_file)
    
    plugin = application_config.get('application', 'plugin')

    if plugin == "sahara":
        executor = Sahara_Plugin()
        executor.run(scaling_config, manager_config, application_config, manager_ip, manager_port, starting_cap)
    elif plugin == "os_generic":
        executor = OS_Generic_Plugin()
        executor.run()

if __name__ == "__main__":
    main()
