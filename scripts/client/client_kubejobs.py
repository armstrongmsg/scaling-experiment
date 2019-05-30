import requests
import json
import ConfigParser
import time
import sys
import signal

from kubernetes import client, config

class GracefulKiller:
    kill_now = False
    def __init__(self):
        signal.signal(signal.SIGINT, self.exit_gracefully)
        signal.signal(signal.SIGTERM, self.exit_gracefully)

    def exit_gracefully(self, signum, frame):
        self.kill_now = True

#
#
# Kubernetes API functions
#
#
def get_k8s_client(kube_config_file):
    try:
        config.load_kube_config(kube_config_file)
    except Exception:
        raise Exception("Couldn't load kube config")
    return client.BatchV1Api()

def get_number_of_replicas(k8s_client, app_id, namespace="default"):
    all_jobs = k8s_client.list_namespaced_job(namespace)
    for job in all_jobs.items:
        if job.metadata.name == app_id:
            return job.spec.parallelism

#
#
# Broker API
#
#
class Broker_Client:
    def __init__(self, experiment_config):
        self.broker_ip = experiment_config.get("broker", "broker_ip")
        self.broker_port = experiment_config.get("broker", "broker_port")

    def get_status(self, job_id):
        r = requests.get('http://%s:%s/submissions/%s' % (self.broker_ip, self.broker_port, job_id))
        return str(r.json()[job_id]['status'])
    
    #FIXME: api should be fixed
    def get_execution_time(self, job_id):
        r = requests.get('http://%s:%s/submissions/%s' % (self.broker_ip, self.broker_port, job_id))
        return r.json()[job_id]['execution_time']
    
    def stop_application(self, job_id):
        body = {
            #FIXME: this should be read from the config file
            "username" : "usr",
            "password" : "psswrd",
            "enable_auth" : False
        }
            
        headers = {'Content-Type': 'application/json'}
        requests.put('http://%s:%s/submissions/%s/stop' % (self.broker_ip, self.broker_port, job_id),
                     headers=headers, data=json.dumps(body))
    
    def submit_application(self, controller, experiment_config, init_size):
        control_parameters = controller.get_parameters()
        expected_time = int(experiment_config.get("application", "expected_time"))
        image_name = experiment_config.get("application", "image_name")
        redis_workload = experiment_config.get("application", "redis_workload")
        #FIXME: this should be read from the config file
        command = [
            "/factorial/run.py"]

        monitor_parameters = {
            "expected_time":expected_time, 
            "datasource_type":"redis"
        }
    
        body = {
            "plugin":"kubejobs",
            "username":"usr",
            "password":"psswrd",
            "plugin_info":{  
            "cmd":command,
            "img":image_name,
            "init_size":init_size,
            "redis_workload":redis_workload,
            "config_id":"id",
            "control_plugin":"kubejobs",
            "control_parameters":control_parameters,
            "monitor_plugin":"kubejobs",
            "monitor_info":monitor_parameters,
            #FIXME: this should be read from the config file
            "enable_visualizer":False,
            "visualizer_plugin":"k8s-grafana",
            "visualizer_info":{  
             "c":"c"},
            "env_vars":{  
             "d":"d"}
            },
            "enable_auth":False
        }
    
        url = "http://%s:%s/submissions" % (self.broker_ip, self.broker_port)
        
        headers = {'Content-Type': 'application/json'}
        r = requests.post(url, headers=headers, data=json.dumps(body))
        return r.json()["job_id"]

#
#
# Controllers
#
#
class PIDController:
    
    def __init__(self, experiment_config, conf):
        self.proportional_factor = float(experiment_config.get(conf, "proportional_factor"))
        self.derivative_factor = float(experiment_config.get(conf, "derivative_factor"))
        self.integrative_factor = float(experiment_config.get(conf, "integrative_factor"))
        self.actuator = experiment_config.get(conf, "actuator")
        self.min_rep = int(experiment_config.get(conf, "min_rep"))
        self.max_rep = int(experiment_config.get(conf, "max_rep"))
            
    def get_parameters(self):
        return {
            "schedule_strategy":"pid", 
            "actuator":self.actuator, 
            "check_interval":5, 
            "trigger_down":0, 
            "trigger_up":0, 
            "min_rep":self.min_rep, 
            "max_rep":self.max_rep, 
            "actuation_size":1, 
            "metric_source":"redis", 
            "heuristic_options":{
                "proportional_factor":self.proportional_factor, 
                "derivative_factor":self.derivative_factor, 
                "integrative_factor":self.integrative_factor}
        }

class DefaultController:
    
    def __init__(self, experiment_config, conf):
        self.max_size = int(experiment_config.get(conf, "max_size"))
        self.actuator = experiment_config.get(conf, "actuator")
        self.check_interval = int(experiment_config.get(conf, "check_interval"))
        self.trigger_down = int(experiment_config.get(conf, "trigger_down"))
        self.trigger_up = int(experiment_config.get(conf, "trigger_up"))
        self.min_rep = int(experiment_config.get(conf, "min_rep"))
        self.max_rep = int(experiment_config.get(conf, "max_rep"))
        self.actuation_size = int(experiment_config.get(conf, "actuation_size"))
        self.metric_source = experiment_config.get(conf, "metric_source")
        
    def get_parameters(self):
        return {
            "schedule_strategy":"default", 
            "max_size":self.max_size,
            "actuator":self.actuator,
            "check_interval":self.check_interval,
            "trigger_down":self.trigger_down,
            "trigger_up":self.trigger_up,
            "min_rep":self.min_rep,
            "max_rep":self.max_rep,
            "actuation_size":self.actuation_size,
            "metric_source":self.metric_source
        }


#
#
# Experiment control
#
#
class Experiment:

    def __init__(self, experiment_config_file):
        self.killer = GracefulKiller()
        self.experiment_config = ConfigParser.RawConfigParser()  
        self.experiment_config.read(experiment_config_file)
        
        self.kube_config_file = self.experiment_config.get("experiment", "kube_config")
        self.output_file_name = self.experiment_config.get("experiment", "output_file")
        self.time_output_file_name = self.experiment_config.get("experiment", "time_output_file")
        
        self.k8s_client = get_k8s_client(self.kube_config_file)
        self.output_file = open(self.output_file_name, "w")
        self.time_output_file = open(self.time_output_file_name, "w")
        
        self.broker_client = Broker_Client(self.experiment_config)
        
        self.wait_after_execution = float(self.experiment_config.get("experiment", 
                                                                     "wait_after_execution"))
        self.wait_check = float(self.experiment_config.get("experiment", "wait_check"))
        self.scaling_confs = self.experiment_config.get("experiment", "confs").split()
        self.reps = int(self.experiment_config.get("experiment", "reps"))
        self.init_sizes = self.experiment_config.get("experiment", "init_size").split()

    def _get_controller(self, experiment_config, conf):
        schedule_strategy = experiment_config.get(conf, "schedule_strategy")
        
        if schedule_strategy == "pid":
            return PIDController(experiment_config, conf)
        elif schedule_strategy == "default":
            return DefaultController(experiment_config, conf)

    def _cleanup(self, job_id):
        self.broker_client.stop_application(job_id)

    def _wait_for_application_to_start(self, job_id):
        status = self.broker_client.get_status(job_id)

        while status != 'ongoing':
            time.sleep(self.wait_check)
            
            if self.killer.kill_now:
                self._cleanup(job_id)
                raise KeyboardInterrupt()
            
            status = self.broker_client.get_status(job_id)
            
    def _wait_for_application_to_finish(self, job_id, rep, conf, init_size):
        start_time = time.time()
        
        status = self.broker_client.get_status(job_id)
        
        while status != 'completed':
            time.sleep(self.wait_check)
            
            if self.killer.kill_now:
                self._cleanup(job_id)
                raise KeyboardInterrupt()
            
            status = self.broker_client.get_status(job_id)
            replicas = get_number_of_replicas(self.k8s_client, job_id)
            if replicas is not None:
                #TODO: improve logging
                self.output_file.write("%s,%d,%s,%d,%f,%d\n" % (job_id, rep, conf, 
                                                                replicas,time.time() - \
                                                                start_time, init_size))
                self.output_file.flush()

    def run_experiment(self):
        for rep in xrange(self.reps):
            print("Rep:%d" % rep)
            
            for i in xrange(len(self.init_sizes)):
                init_size = int(self.init_sizes[i])
                print("Init size:%s" % init_size)
            
                for conf in self.scaling_confs:
                    print("Conf:%s" % conf)
            
                    controller = self._get_controller(self.experiment_config, conf)
                    job_id = self.broker_client.submit_application(controller, 
                                                self.experiment_config, init_size)

                    self._wait_for_application_to_start(job_id)
                    self._wait_for_application_to_finish(job_id, rep, conf, init_size)

                    execution_time = self.broker_client.get_execution_time(job_id)
                
                    #TODO: improve logging
                    self.time_output_file.write("%s,%d,%s,%f,%d\n" % (job_id, rep, conf, 
                                                                      execution_time, init_size))
                    self.time_output_file.flush()
                    
                    print("Finished execution")
                    
                    time.sleep(self.wait_after_execution)
        
        #TODO: improve logging
        #TODO: zip files?
        self.output_file.close()
        self.time_output_file.close()
    
if __name__ == '__main__':
    experiment_config_file = sys.argv[1]
    experiment = Experiment(experiment_config_file)
    
    try:
        experiment.run_experiment()
    except KeyboardInterrupt:
        print("Stopping execution on user request")
    except Exception as e:
        print(e)
