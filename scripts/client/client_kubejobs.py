import requests
import json
import ConfigParser
import time
import sys

from kubernetes import client, config

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
# Broker API functions
#
#
def get_status(broker_ip, broker_port, job_id):
    r = requests.get('http://%s:%s/submissions/%s' % (broker_ip, broker_port, job_id))
    return str(r.json()[job_id]['status'])

# FIXME api should be fixed
def get_execution_time(broker_ip, broker_port, job_id):
    r = requests.get('http://%s:%s/submissions/%s' % (broker_ip, broker_port, job_id))
    return r.json()[job_id]['execution_time']

def submit_application(experiment_config, conf):
    expected_time = int(experiment_config.get("application", "expected_time"))
    image_name = experiment_config.get("application", "image_name")
    redis_workload = experiment_config.get("application", "redis_workload")
    command = [
        "/factorial/run.py"]
    init_size = int(experiment_config.get("application", "init_size"))
    
    control_parameters = get_control_parameters(conf)

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
        "enable_visualizer":False,
        "visualizer_plugin":"k8s-grafana",
        "visualizer_info":{  
         "c":"c"},
        "env_vars":{  
         "d":"d"}
        },
        "enable_auth":False
    }

    url = "http://%s:%s/submissions" % (broker_ip, broker_port)
    
    headers = {'Content-Type': 'application/json'}
    r = requests.post(url, headers=headers, data=json.dumps(body))
    return r.json()["job_id"]

#
#
# Parameter reading functions
#
#
def get_pid_control_parameters(conf):
    proportional_factor = float(experiment_config.get(conf, "proportional_factor"))
    derivative_factor = float(experiment_config.get(conf, "derivative_factor"))
    integrative_factor = float(experiment_config.get(conf, "integrative_factor"))
    actuator = experiment_config.get(conf, "actuator")
    min_rep = int(experiment_config.get(conf, "min_rep"))
    max_rep = int(experiment_config.get(conf, "max_rep"))
        
    return {
        "schedule_strategy":"pid", 
        "actuator":actuator, 
        "check_interval":5, 
        "trigger_down":0, 
        "trigger_up":0, 
        "min_rep":min_rep, 
        "max_rep":max_rep, 
        "actuation_size":1, 
        "metric_source":"redis", 
        "heuristic_options":{
            "proportional_factor":proportional_factor, 
            "derivative_factor":derivative_factor, 
            "integrative_factor":integrative_factor}
    }

def get_default_control_parameters(conf):
    max_size = int(experiment_config.get(conf, "max_size"))
    actuator = experiment_config.get(conf, "actuator")
    check_interval = int(experiment_config.get(conf, "check_interval"))
    trigger_down = int(experiment_config.get(conf, "max_size"))
    trigger_up = int(experiment_config.get(conf, "max_size"))
    min_rep = int(experiment_config.get(conf, "min_rep"))
    max_rep = int(experiment_config.get(conf, "max_rep"))
    actuation_size = int(experiment_config.get(conf, "max_size"))
    metric_source = experiment_config.get(conf, "metric_source")
    
    return {
        "schedule_strategy":"default", 
        "max_size":max_size,
        "actuator":actuator,
        "check_interval":check_interval,
        "trigger_down":trigger_down,
        "trigger_up":trigger_up,
        "min_rep":min_rep,
        "max_rep":max_rep,
        "actuation_size":actuation_size,
        "metric_source":metric_source
    }

def get_control_parameters(conf):
    schedule_strategy = experiment_config.get(conf, "schedule_strategy")
    control_parameters = None
    
    if schedule_strategy == "pid":
        control_parameters = get_pid_control_parameters(conf)
    elif schedule_strategy == "default":
        control_parameters = get_default_control_parameters(conf)
     
    return control_parameters

if __name__ == '__main__':
    experiment_config_file = sys.argv[1]
    experiment_config = ConfigParser.RawConfigParser()  
    experiment_config.read(experiment_config_file)
    
    kube_config_file = experiment_config.get("experiment", "kube_config")
    output_file_name = experiment_config.get("experiment", "output_file")
    time_output_file_name = experiment_config.get("experiment", "time_output_file")
    
    k8s_client = get_k8s_client(kube_config_file)
    output_file = open(output_file_name, "w")
    time_output_file = open(time_output_file_name, "w")
    
    broker_ip = experiment_config.get("broker", "broker_ip")
    broker_port = experiment_config.get("broker", "broker_port")

    scaling_confs = experiment_config.get("experiment", "confs").split()
    reps = int(experiment_config.get("experiment", "reps"))
    
    for rep in xrange(reps):
        print("Rep:%d" % rep)
        
        for conf in scaling_confs:
            print ("Conf:%s" % conf)
    
            job_id = submit_application(experiment_config, conf)
            status = get_status(broker_ip, broker_port, job_id)
    
            while status != 'ongoing':
                time.sleep(1)
                status = get_status(broker_ip, broker_port, job_id)
            
            start_time = time.time()
            
            while status != 'completed':
                time.sleep(1)
                status = get_status(broker_ip, broker_port, job_id)
                replicas = get_number_of_replicas(k8s_client, job_id)
                if replicas is not None:
                    output_file.write("%s,%d,%s,%d,%f\n" % (job_id, rep, conf, replicas,time.time() - start_time))
                    output_file.flush()
                    
            end_time = time.time()
            execution_time = end_time - start_time
        
            time_output_file.write("%s,%d,%s,%f\n" % (job_id, rep, conf, execution_time))
            time_output_file.flush()
        
    output_file.close()
    time_output_file.close()

