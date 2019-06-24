import requests
import json
import ConfigParser
import time
import sys
import signal
import logging
import zipfile
import os
import ast
import redis

from kubernetes import client, config


#
#
# Utils
#
#
def zip_files(zip_name, *file_names):
    zipf = zipfile.ZipFile(zip_name, "w", zipfile.ZIP_DEFLATED)
    
    for file_name in file_names:
        zipf.write(file_name)
    
    zipf.close()

class Log:
    def __init__(self, name, output_file_path):
        self.logger = logging.getLogger(name)
        if not len(self.logger.handlers):
            handler = logging.StreamHandler()
            handler.setLevel(logging.INFO)
            self.logger.addHandler(handler)
            handler = logging.FileHandler(output_file_path)
            self.logger.addHandler(handler)

    def log(self, text):
        self.logger.info(text)

def configure_logging(logging_level="INFO"):
    levels = {"CRITICAL": logging.CRITICAL, "DEBUG": logging.DEBUG,
              "ERROR": logging.ERROR, "FATAL": logging.FATAL,
              "INFO": logging.INFO, "NOTSET": logging.NOTSET,
              "WARN": logging.WARN, "WARNING": logging.WARNING
              }

    logging.basicConfig(level=levels[logging_level])

class CSVFile:
    def __init__(self, output_file_name, header):
        configure_logging()
        self.output_log = Log(output_file_name, output_file_name)
        self.output_log.log(header.strip())
        
    def writeline(self, *fields):
        line = ",".join(str(e) for e in fields)
        self.output_log.log(line)

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
        self.enable_auth = experiment_config.get("authentication", "user") == "True"
        self.user = experiment_config.get("authentication", "user")
        self.password = experiment_config.get("authentication", "password")
        
        self.redis_client = None

    def get_status(self, job_id):
        r = requests.get('http://%s:%s/submissions/%s' % (self.broker_ip, self.broker_port, job_id))
        return str(r.json()['status'])
    
    #FIXME: api should be fixed
    def get_execution_time(self, job_id):
        r = requests.get('http://%s:%s/submissions/%s' % (self.broker_ip, self.broker_port, job_id))
        return r.json()[job_id]['execution_time']
    
    def stop_application(self, job_id):
        body = {
            "username" : self.user,
            "password" : self.password,
            "enable_auth" : self.enable_auth
        }
            
        headers = {'Content-Type': 'application/json'}
        requests.put('http://%s:%s/submissions/%s/stop' % (self.broker_ip, self.broker_port, job_id),
                     headers=headers, data=json.dumps(body))
    
    def submit_application(self, controller, experiment_config, init_size):
        control_parameters = controller.get_parameters()
        expected_time = int(experiment_config.get("application", "expected_time"))
        image_name = experiment_config.get("application", "image_name")
        redis_workload = experiment_config.get("application", "redis_workload")
        application_command = experiment_config.get("application", "command")
        command = [ application_command ]

        monitor_parameters = {
            "expected_time":expected_time, 
            "datasource_type":"redis"
        }
    
        body = {
            "plugin":"kubejobs",
            "username":self.user,
            "password":self.password,
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
                #TODO: this should be read from the config file
                "enable_visualizer":False,
                "visualizer_plugin":"k8s-grafana",
                "visualizer_info":{},
                "env_vars":{}
            },
            "enable_auth":self.enable_auth
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
        self.proportional_gain = float(experiment_config.get(conf, "proportional_gain"))
        self.derivative_gain = float(experiment_config.get(conf, "derivative_gain"))
        self.integral_gain = float(experiment_config.get(conf, "integral_gain"))
        self.actuator = experiment_config.get(conf, "actuator")
        self.min_rep = int(experiment_config.get(conf, "min_rep"))
        self.max_rep = int(experiment_config.get(conf, "max_rep"))
        self.check_interval = int(experiment_config.get(conf, "check_interval"))
            
    def get_parameters(self):
        return {
            "schedule_strategy":"pid", 
            "actuator":self.actuator, 
            "check_interval":self.check_interval,
            "trigger_down":0, 
            "trigger_up":0, 
            "min_rep":self.min_rep, 
            "max_rep":self.max_rep, 
            "actuation_size":1, 
            "metric_source":"redis", 
            "heuristic_options":{
                "proportional_gain":self.proportional_gain, 
                "derivative_gain":self.derivative_gain, 
                "integral_gain":self.integral_gain
            }
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
        self.experiment_config_file = experiment_config_file
        self.experiment_config = ConfigParser.RawConfigParser()  
        self.experiment_config.read(experiment_config_file)
        
        #
        # Logging
        #
        self.kube_config_file = self.experiment_config.get("experiment", "kube_config")
        self.output_file_name = self.experiment_config.get("experiment", "output_file")
        self.time_output_file_name = self.experiment_config.get("experiment", "time_output_file")
        self.log_file = self.experiment_config.get("experiment", "log_file")
        self.archive_directory = self.experiment_config.get("experiment", "archive_directory")
        
        if not os.path.isdir(self.archive_directory):
            raise Exception("Archive directory does not exist")
        
        self.cap_output = CSVFile(self.output_file_name, 
                                      "exec_id,rep,controller,replicas,time,init_size,error,queue_length,processing_jobs")
        self.time_output = CSVFile(self.time_output_file_name, 
                                       "exec_id,rep,controller,execution_time,init_size")
        self.log = Log("experiment", self.log_file)
        
        self.k8s_client = get_k8s_client(self.kube_config_file)
        self.broker_client = Broker_Client(self.experiment_config)
        
        #
        # Experiment config
        #
        self.wait_after_execution = float(self.experiment_config.get("experiment", 
                                                                     "wait_after_execution"))
        self.wait_check = float(self.experiment_config.get("experiment", "wait_check"))
        self.scaling_confs = self.experiment_config.get("experiment", "confs").split()
        self.reps = int(self.experiment_config.get("experiment", "reps"))
        self.init_sizes = self.experiment_config.get("experiment", "init_size").split()
        
        self.job_id = None

    def _get_controller(self, experiment_config, conf):
        schedule_strategy = experiment_config.get(conf, "schedule_strategy")
        
        if schedule_strategy == "pid":
            return PIDController(experiment_config, conf)
        elif schedule_strategy == "default":
            return DefaultController(experiment_config, conf)

    def _cleanup(self):
        self.broker_client.stop_application(self.job_id)

    def _wait_for_application_to_start(self, job_id):
        status = self.broker_client.get_status(job_id)

        while status != 'ongoing':
            time.sleep(self.wait_check)
            
            if self.killer.kill_now:
                self._cleanup()
                raise KeyboardInterrupt()
            
            status = self.broker_client.get_status(job_id)
    
    def _get_redis_port(self, job_id, kube_config, namespace="default"):
        config.load_kube_config(kube_config)
        k8s_client = client.CoreV1Api()
        services_info = k8s_client.list_namespaced_service(namespace)
        
        for item in services_info.items:
            if item.spec.selector != None and item.spec.selector['app'] == 'redis-' + job_id:
                redis_port = services_info.items[1].spec.ports[0].node_port
                return redis_port
        
    def _get_queue_len(self):
        return self.redis_client.llen('job')
    
    def _get_processing_jobs(self):
        return self.redis_client.llen('job:processing')
    
    def _get_error(self, job_id):
        measurement = self.redis_client.lrange("%s:metrics" % job_id, -1, -1)
    
        if measurement is not None and len(measurement) > 0:
            measurement = ast.literal_eval(measurement[0])
            value = float(measurement['value'])
            return value
        else:
            return 0.0
        
    def _get_redis_client(self, job_id, kube_config_file):
        redis_port = self._get_redis_port(job_id, kube_config_file)
        self.redis_client = redis.StrictRedis(self.broker_client.broker_ip, redis_port)
    
    def _wait_for_application_to_finish(self, job_id, rep, conf, init_size):
        start_time = time.time()
        
        status = self.broker_client.get_status(job_id)
        self._get_redis_client(job_id, self.kube_config_file)
        
        while status != 'completed':
            time.sleep(self.wait_check)

            if self.killer.kill_now:
                self._cleanup()
                raise KeyboardInterrupt()
            
            status = self.broker_client.get_status(job_id)
            replicas = get_number_of_replicas(self.k8s_client, job_id)
            error = self._get_error(job_id)
            queue_length = self._get_queue_len()
            processing_jobs = self._get_processing_jobs()
            
            if replicas is not None:
                self.cap_output.writeline(job_id, rep, conf, replicas, time.time() - \
                                          start_time, init_size, error, queue_length, processing_jobs)

        return time.time() - start_time
    
    def _backup_experiment_data(self):
        archive_filename = os.path.join(self.archive_directory, 
                                        "%s.zip" % (time.strftime("%Y%m%d-%H%M%S")))
        zip_files(archive_filename, self.output_file_name, 
                                    self.time_output_file_name, 
                                    self.log_file,
                                    self.experiment_config_file)

    def run_experiment(self):
        for rep in xrange(self.reps):
            self.log.log("Rep:%d" % rep)
            
            for i in xrange(len(self.init_sizes)):
                init_size = int(self.init_sizes[i])
                self.log.log("Init size:%s" % init_size)
            
                for conf in self.scaling_confs:
                    self.log.log("Conf:%s" % conf)
            
                    controller = self._get_controller(self.experiment_config, conf)
                    job_id = self.broker_client.submit_application(controller, 
                                                self.experiment_config, init_size)
                    self.job_id = job_id
                    self._wait_for_application_to_start(job_id)
                    
                    execution_time = self._wait_for_application_to_finish(job_id, rep, conf, init_size)

                    self.time_output.writeline(job_id, rep, conf, execution_time, init_size)
                    self.log.log("Finished execution")
                    
                    time.sleep(self.wait_after_execution)
                    
        self._backup_experiment_data()
    
if __name__ == '__main__':
    experiment_config_file = sys.argv[1]
    experiment = Experiment(experiment_config_file)
    
    try:
        experiment.run_experiment()
    except KeyboardInterrupt:
        print("Stopping execution at user request")
        if experiment is not None:
            experiment.log.log("Stopping execution at user request")
    finally:
        if experiment is not None:
            experiment._cleanup()
