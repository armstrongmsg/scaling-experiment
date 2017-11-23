import ConfigParser
import json
import os
import requests
import sys
import uuid

class Scaling_Plugin:

    def get_proportional_plugin_parameters(self, scaling_config):
        scaler_plugin = scaling_config.get('scaler', 'scaler_plugin')
        check_interval = scaling_config.getint('scaler', 'check_interval')
        trigger_down = scaling_config.getint('scaler', 'trigger_down')
        trigger_up = scaling_config.getint('scaler', 'trigger_up')
        min_cap = scaling_config.getint('scaler', 'min_cap')
        max_cap = scaling_config.getint('scaler', 'max_cap')
        metric_rounding = scaling_config.getint('scaler', 'metric_rounding')
        heuristic_name = scaling_config.get('scaler', 'heuristic_name')
                
        heuristic_options = {}
        heuristic_options['heuristic_name'] = heuristic_name
                
        if heuristic_name == 'error_proportional':
            proportional_factor = scaling_config.getfloat('scaler', 'proportional_factor')
            heuristic_options['proportional_factor'] = proportional_factor
        elif heuristic_name == 'error_proportional_up_down':
            factor_up = scaling_config.getfloat('scaler', 'factor_up')
            factor_down = scaling_config.getfloat('scaler', 'factor_down')
            heuristic_options['factor_up'] = factor_up
            heuristic_options['factor_down'] = factor_down
            
        scaling_parameters = {'check_interval':check_interval,
                            'trigger_down':trigger_down, 'trigger_up':trigger_up,
                            'min_cap':min_cap, 'max_cap':max_cap, 'metric_rounding':metric_rounding,
                            'heuristic_options': heuristic_options, 
                            'scaler_plugin':scaler_plugin}
        
        return scaling_parameters

    def get_proportional_derivative_parameters(self, scaling_config):
        scaler_plugin = scaling_config.get('scaler', 'scaler_plugin')
        check_interval = scaling_config.getint('scaler', 'check_interval')
        trigger_down = scaling_config.getint('scaler', 'trigger_down')
        trigger_up = scaling_config.getint('scaler', 'trigger_up')
        min_cap = scaling_config.getint('scaler', 'min_cap')
        max_cap = scaling_config.getint('scaler', 'max_cap')
        metric_rounding = scaling_config.getint('scaler', 'metric_rounding')
        heuristic_name = scaling_config.get('scaler', 'heuristic_name')
                
        heuristic_options = {}
        heuristic_options['heuristic_name'] = heuristic_name
        
        if heuristic_name == 'error_proportional_derivative':
            proportional_factor = scaling_config.getfloat('scaler', 'proportional_factor')
            derivative_factor = scaling_config.getfloat('scaler', 'derivative_factor')
            heuristic_options['proportional_factor'] = proportional_factor
            heuristic_options['derivative_factor'] = derivative_factor
            
        scaling_parameters = {'check_interval':check_interval,
                            'trigger_down':trigger_down, 'trigger_up':trigger_up,
                            'min_cap':min_cap, 'max_cap':max_cap, 'metric_rounding':metric_rounding,
                            'heuristic_options': heuristic_options, 
                            'scaler_plugin':scaler_plugin}
        
        return scaling_parameters

    def get_progress_error_parameters(self, scaling_config):
        scaler_plugin = scaling_config.get('scaler', 'scaler_plugin')
        check_interval = scaling_config.getint('scaler', 'check_interval')
        trigger_down = scaling_config.getint('scaler', 'trigger_down')
        trigger_up = scaling_config.getint('scaler', 'trigger_up')
        min_cap = scaling_config.getint('scaler', 'min_cap')
        max_cap = scaling_config.getint('scaler', 'max_cap')
        actuation_size = scaling_config.getint('scaler', 'actuation_size')
        metric_rounding = scaling_config.getint('scaler', 'metric_rounding')
            
        scaling_parameters = {'check_interval':check_interval,
                                'trigger_down':trigger_down, 'trigger_up':trigger_up,
                                'min_cap':min_cap, 'max_cap':max_cap,
                                'actuation_size':actuation_size, 'metric_rounding':metric_rounding,
                                "scaler_plugin":scaler_plugin}
        
        return scaling_parameters
    
    def get_scaling_parameters(self, scaling_config_filename):
        scaling_config = ConfigParser.RawConfigParser()
        scaling_config.read(scaling_config_filename)
        
        scaler_plugin = scaling_config.get('scaler', 'scaler_plugin')
        
        if scaler_plugin == 'progress-error' or scaler_plugin == 'progress-tendency':
            scaling_parameters = self.get_progress_error_parameters(scaling_config)    
        elif scaler_plugin == 'proportional':
            scaling_parameters = self.get_proportional_plugin_parameters(scaling_config)
        elif scaler_plugin == 'proportional_derivative':
            scaling_parameters = self.get_proportional_derivative_parameters(scaling_config)
                    
        return scaling_parameters       

def get_manager_parameters(manager_config_filename):
    manager_config = ConfigParser.RawConfigParser()
    manager_config.read(manager_config_filename)
    
    manager_parameters = {}
    
    bigsea_username = manager_config.get('manager', 'bigsea_username')
    bigsea_password = manager_config.get('manager', 'bigsea_password')
    percentage = manager_config.getint('manager', 'percentage')
    spark_master_ip = manager_config.get('manager', 'spark_master_ip')
    
    manager_parameters["bigsea_username"] = bigsea_username
    manager_parameters["bigsea_password"] = bigsea_password
    manager_parameters["percentage"] = percentage
    manager_parameters["spark_master_ip"] = spark_master_ip
    
    return manager_parameters

class OS_Generic_Plugin:
    
    def __init__(self, scaling_parameters, manager_parameters, application_config, manager_ip, 
                                                    manager_port, starting_cap):
        self.scaling_parameters = scaling_parameters
        self.manager_parameters = manager_parameters
        self.application_config = application_config
        self.manager_ip = manager_ip
        self.manager_port = manager_port
        self.starting_cap = starting_cap
    
    def run(self):
        plugin = self.application_config.get('application', 'plugin')
        
        command = self.application_config.get('application', 'command')
        reference_value = self.application_config.getfloat('application', 'reference_value')
        log_path = self.application_config.get('application', 'log_path')
        opportunistic = self.application_config.get('application', 'opportunistic')
        metric_source = self.application_config.get('application', 'metric_source')
        
        image_id = self.application_config.get('application', 'image_id')
        flavor_id = self.application_config.get('application', 'flavor_id')
        
        cluster_size = self.application_config.getint('application', 'cluster_size')
        
        scaler_plugin = self.scaling_parameters['scaler_plugin']
        actuator = self.scaling_parameters['actuator']
        self.scaling_parameters['metric_source'] = metric_source

        headers = {'Content-Type': 'application/json'}
        body = dict(plugin=plugin, scaler_plugin=scaler_plugin, opportunistic=opportunistic,
            scaling_parameters=self.scaling_parameters, actuator=actuator, 
            starting_cap=self.starting_cap, flavor_id=flavor_id, 
            image_id=image_id, command=command,
            reference_value=reference_value, log_path=log_path, cluster_size=cluster_size,
            bigsea_username=self.manager_parameters["bigsea_username"], 
            bigsea_password=self.manager_parameters["bigsea_password"])

        url = "http://%s:%s/manager/execute" % (self.manager_ip, self.manager_port)
        r = requests.post(url, headers=headers, data=json.dumps(body))
        print r.content

class Sahara_Plugin:
    
    def __init__(self, scaling_parameters, manager_parameters, application_config, manager_ip, 
                                                    manager_port, starting_cap):
        self.scaling_parameters = scaling_parameters
        self.manager_parameters = manager_parameters
        self.application_config = application_config
        self.manager_ip = manager_ip
        self.manager_port = manager_port
        self.starting_cap = starting_cap
    
    def run(self): 
        plugin = self.application_config.get('application', 'plugin')
        opportunistic = self.application_config.get('application', 'opportunistic')
        main_class = self.application_config.get('application', 'main_class')
        job_template_name = self.application_config.get('application', 'job_template_name')
        job_binary_name = self.application_config.get('application', 'job_binary_name')
        
        args = self.application_config.get('application', 'args').split()
        
        if job_binary_name == "EMaaS":
            args[2] = args[2] + str(uuid.uuid4())[0:5]
        elif job_binary_name == "KMeans":
            args[1] = args[1] + str(uuid.uuid4())[0:5]
        
        job_binary_url = self.application_config.get('application', 'job_binary_url')
        input_ds_id = ''
        output_ds_id = ''
        plugin_app = self.application_config.get('application', 'plugin_app')
        expected_time = self.application_config.getint('application', 'expected_time')
        collect_period = self.application_config.getint('application', 'collect_period')
        openstack_plugin = self.application_config.get('application', 'openstack_plugin')
        job_type = self.application_config.get('application', 'job_type')
        version = '1.6.0'
        slave_ng = self.application_config.get('application', 'slave_ng')
        master_ng = self.application_config.get('application', 'master_ng')
        net_id = self.application_config.get('application', 'net_id')
        opportunistic_slave_ng = self.application_config.get('application', 'opportunistic_slave_ng')
        dependencies = ""
        
        cluster_size = self.application_config.getint('application', 'cluster_size')
        
        image_id = self.application_config.get('application', 'image_id')
        flavor_id = self.application_config.get('application', 'flavor_id')
        
        metric_source = self.application_config.get('application', 'metric_source')
        self.scaling_parameters['metric_source'] = metric_source
        
        total_tasks = 0
        
        number_of_jobs = self.application_config.get('application', 'number_of_jobs')
        
        if metric_source == 'spark':
            total_tasks = self.application_config.get('application', 'total_tasks')
            #spark_master_ip = self.application_config.get('application', 'spark_master_ip')
        
        headers = {'Content-Type': 'application/json'}
        body = dict(plugin=plugin, scaler_plugin=self.scaling_parameters["scaler_plugin"],
            scaling_parameters=self.scaling_parameters, cluster_size=cluster_size,
            percentage=self.manager_parameters["percentage"],
            starting_cap=self.scaling_parameters["starting_cap"], 
            actuator=self.scaling_parameters["actuator"],
            flavor_id=flavor_id, image_id=image_id, 
            opportunistic=opportunistic, args=args, main_class=main_class, 
            job_template_name=job_template_name, job_binary_name=job_binary_name, 
            job_binary_url=job_binary_url, input_ds_id=input_ds_id, output_ds_id=output_ds_id, 
            plugin_app=plugin_app, expected_time=expected_time, 
            collect_period=collect_period, dependencies=dependencies,
            bigsea_username=self.manager_parameters["bigsea_username"],
            bigsea_password=self.manager_parameters["bigsea_password"], 
            openstack_plugin=openstack_plugin, job_type=job_type, version=version, 
            slave_ng=slave_ng, master_ng=master_ng, net_id=net_id, 
            opportunistic_slave_ng=opportunistic_slave_ng,
            total_tasks=total_tasks, number_of_jobs=number_of_jobs, 
            spark_master_ip=self.manager_parameters["spark_master_ip"],
            )
        
        url = "http://%s:%s/manager/execute" % (self.manager_ip, self.manager_port)
        r = requests.post(url, headers=headers, data=json.dumps(body))
        print str(r.content).strip()

def main():
    conf_dir = sys.argv[1]
    manager_ip = sys.argv[2]
    manager_port = sys.argv[3]
    starting_cap = sys.argv[4]
    actuator = sys.argv[5]
    
    application_config = ConfigParser.RawConfigParser()
    
    scaling_config_file = os.path.join(conf_dir, 'scaling.cfg')
    manager_config_file = os.path.join(conf_dir, 'manager.cfg')
    application_config_file = os.path.join(conf_dir, 'application.cfg')

    application_config.read(application_config_file)
    
    plugin = application_config.get('application', 'plugin')

    scaling_plugin = Scaling_Plugin()
    scaling_plugin_parameters = scaling_plugin.get_scaling_parameters(scaling_config_file)
    scaling_plugin_parameters['actuator'] = actuator
    scaling_plugin_parameters['starting_cap'] = starting_cap
    
    if plugin == "sahara":
        executor = Sahara_Plugin(scaling_plugin_parameters, 
                     get_manager_parameters(manager_config_file), 
                     application_config, manager_ip, manager_port, starting_cap)
    elif plugin == "os_generic":
        executor = OS_Generic_Plugin(scaling_plugin_parameters, 
                     get_manager_parameters(manager_config_file), 
                     application_config, manager_ip, manager_port, starting_cap)
        
    executor.run()

if __name__ == "__main__":
    main()
