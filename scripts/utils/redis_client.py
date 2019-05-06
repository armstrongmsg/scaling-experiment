import time
import kubernetes as kube
import redis
import sys
    
def start_redis(redis_ip, kube_config):
    app_id = "app"
    namespace="default"
    redis_port=6379
    timeout=60
    # name redis instance as ``redis-{app_id}``
    name = "redis-%s" % app_id
    
    # load kubernetes config
    kube.config.load_kube_config(kube_config)
 
    # create the Pod object for redis
    redis_pod_spec = {
        "apiVersion": "v1",
        "kind": "Pod",
        "metadata": {
            "name": name,
            "labels": {
                "app": name
            }
        },
        "spec": {
            "containers": [{
                "name": "redis-master",
                "image": "redis",
                "env": [{
                    "name": "MASTER",
                    "value": str(True)
                }],
                "ports": [{
                    "containerPort": redis_port
                }]
            }]
        }
    }
 
    # create the Service object for redis
    redis_svc_spec = {
        "apiVersion": "v1",
        "kind": "Service",
        "metadata": {
            "name": name
        },
        "spec": {
            "ports": [{
                "port": redis_port,
                "targetPort": redis_port
            }],
            "selector": {
                "app": name
            },
            "type": "NodePort"
        }
    }
 
    # create Pod and Service
    CoreV1Api = kube.client.CoreV1Api()
    node_port = None
    try:
        CoreV1Api.create_namespaced_pod(
            namespace=namespace, body=redis_pod_spec)
        s = CoreV1Api.create_namespaced_service(
            namespace=namespace, body=redis_svc_spec)
        node_port = s.spec.ports[0].node_port
    except kube.client.rest.ApiException as e:
        print e
 
    # wait until the redis instance is Ready
    # (ie. accessible via the Service)
    # if it takes longer than ``timeout`` seconds, die
    redis_ready = False
    start = time.time()
    while time.time() - start < timeout:
        time.sleep(5)
        try:
            r = redis.StrictRedis(host=redis_ip, port=node_port)
            if r.info()['loading'] == 0:
                redis_ready = True
                break
        except redis.exceptions.ConnectionError:
            pass
 
    if redis_ready:
        return redis_ip, node_port
    else:
        delete_redis_resources(app_id=app_id)
        raise Exception("Could not provision redis")

def stop_redis(kube_config, namespace="default"):
    app_id = "app"
    # load kubernetes config
    kube.config.load_kube_config(kube_config)
 
    CoreV1Api = kube.client.CoreV1Api()
 
    name = "redis-%s" % app_id
    delete = kube.client.V1DeleteOptions()
    CoreV1Api.delete_namespaced_pod(
        name=name, namespace=namespace, body=delete)
    CoreV1Api.delete_namespaced_service(
        name=name, namespace=namespace, body=delete)

def add_data_to_redis(redis_ip, redis_port, data_file_name):
    data_file = open(data_file_name, "r")
    data = data_file.readlines()
    
    rds = redis.StrictRedis(host=redis_ip, port=redis_port)
    
    for job in data:
        rds.rpush("job", job)
    
    data_file.close()
        
def get_redis_queue_len(redis_ip, redis_port):
    rds = redis.StrictRedis(host=redis_ip, port=redis_port)
    
    return rds.llen('job')
    
if __name__ == "__main__":
    function = sys.argv[1]     
    redis_ip = sys.argv[2]
    redis_port = sys.argv[3]
    kube_config = sys.argv[4]
    
    if function == "start":
        redis_ip, node_port = start_redis(redis_ip, kube_config)
        print(node_port)
    elif function == "stop":
        stop_redis(kube_config)
    elif function == "data":
        data_file_name = sys.argv[5]
        add_data_to_redis(redis_ip, redis_port, data_file_name)
    elif function == "len":
        print(get_redis_queue_len(redis_ip, redis_port))
        