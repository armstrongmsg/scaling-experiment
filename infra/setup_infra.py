#!/usr/bin/python

from keystoneauth1 import loading
from keystoneauth1 import session
from novaclient import client
import paramiko
import time
import ConfigParser
import subprocess

class OpenStackUtils:
    
    def get_instance_status(self, nova, instance_id):
        instance = nova.servers.get(instance_id)
        if u'status' in instance._info.keys():
            return instance._info[u'status']
        else:
            return "no status available"

    def get_nova_client(self, auth_url, username, password, project_name, project_domain_name, user_domain_name):
        loader = loading.get_plugin_loader('password')
        auth = loader.load_from_options(auth_url=auth_url, username=username, password=password, 
                                        project_name=project_name, project_domain_name=project_domain_name,
                                        user_domain_name=user_domain_name)
        sess = session.Session(auth=auth)
        return client.Client("2", session=sess)

    def create_instance(self, instance_name, nova_client, flavor_name, image_name, key_name):
        fl = nova_client.flavors.find(name=flavor_name)
        im = nova_client.images.find(name=image_name)
        server = nova_client.servers.create(instance_name, flavor=fl, image=im, key_name=key_name)
        return server.id
    
    def instance_is_active(self, nova_client, instance_id):
        instance_status = self.get_instance_status(nova_client, instance_id)

        while instance_status != 'ACTIVE':
            instance_status = self.get_instance_status(nova_client, instance_id)
            print instance_status
            
    def ssh_is_available(self, nova_client, instance_id):
        server = nova_client.servers.get(instance_id)
        ip = server.networks["provider"][0]
        
        #FIXME:
        subprocess.call("ssh-keygen -f '/home/armstrongmsg/.ssh/known_hosts' -R %s" % (ip), shell=True)
        
        attempts = 10

        while attempts != -1:
            try:
                conn = get_ssh_connection(ip, "ubuntu", "/home/armstrongmsg/.ssh/bigsea-spark-master-key.pem")
                attempts = -1
            except:
                print "Fail to connect "
                attempts -= 1
                time.sleep(2)
                
    def delete_instance(self, nova_client, instance_id):
        server = nova_client.servers.get(instance_id)
        server.delete()

    def get_instance_ip(self, nova_client, instance_id):
        server = nova_client.servers.get(instance_id)
        return server.networks["provider"][0]

def get_ssh_connection(ip, username, keypair_path):
    keypair = paramiko.RSAKey.from_private_key_file(keypair_path)
    conn = paramiko.SSHClient()
    conn.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    conn.connect(hostname=ip, username=username, pkey=keypair)
    return conn

def scp(local_path, user, ip, remote_path, key_path):
    print "scp -i %s %s %s@%s:%s" % (key_path, local_path, user, ip, remote_path)
    subprocess.call('scp -o "StrictHostKeyChecking no" -i %s %s %s@%s:%s' % (key_path, local_path, user, ip, remote_path), shell = True)

def start_scaler(os, nova):
    config = ConfigParser.RawConfigParser()

    config.read("experiment.cfg")
    
    key_name = config.get("os-auth", "key_name")
    instance_name = config.get("os-instance", "name")
    instance_flavor = config.get("os-instance", "flavor")
    instance_image = config.get("os-instance", "image")
    instance_key_path = config.get("os-instance", "key_path")
    instance_user = config.get("os-instance", "user")
    
    instance_id = os.create_instance(instance_name + "-scaler", nova, flavor_name=instance_flavor, image_name=instance_image, key_name=key_name)
    
    os.instance_is_active(nova, instance_id)
    os.ssh_is_available(nova, instance_id)
    
    instance_ip = os.get_instance_ip(nova, instance_id)
    
    conn = get_ssh_connection(instance_ip, instance_user, instance_key_path)
    
    stdin , stdout, stderr = conn.exec_command("sudo apt-get update")
    
    print stdout.read()
    print stderr.read()
    
    stdin , stdout, stderr = conn.exec_command("sudo apt-get install -y git")
    
    print stdout.read()
    print stderr.read()
    
    stdin, stdout, stderr = conn.exec_command("git clone https://github.com/bigsea-ufcg/bigsea-scaler.git")
    
    print stdout.read()
    print stderr.read()
    
    stdin , stdout, stderr = conn.exec_command("cd bigsea-scaler; sudo ./setup.sh")
    
    print stdout.read()
    print stderr.read()
    
    scp("controller.cfg", instance_user, instance_ip, "/home/ubuntu/bigsea-scaler", instance_key_path)
    scp("monitor.cfg", instance_user, instance_ip, "/home/ubuntu/bigsea-scaler", instance_key_path)
    
    stdin , stdout, stderr = conn.exec_command("cd bigsea-scaler; ./run.sh &")
    
    #print stdout.read()
    #print stderr.read()

def start_monitor(os, nova):
    config = ConfigParser.RawConfigParser()

    config.read("experiment.cfg")
    
    key_name = config.get("os-auth", "key_name")
    instance_name = config.get("os-instance", "name")
    instance_flavor = config.get("os-instance", "flavor")
    instance_image = config.get("os-instance", "image")
    instance_key_path = config.get("os-instance", "key_path")
    instance_user = config.get("os-instance", "user")
    
    instance_id = os.create_instance(instance_name + "-monitor", nova, flavor_name=instance_flavor, image_name=instance_image, key_name=key_name)
    
    os.instance_is_active(nova, instance_id)
    os.ssh_is_available(nova, instance_id)
    
    instance_ip = os.get_instance_ip(nova, instance_id)
    
    conn = get_ssh_connection(instance_ip, instance_user, instance_key_path)
    
    stdin , stdout, stderr = conn.exec_command("sudo apt-get update")
    
    print stdout.read()
    print stderr.read()
    
    stdin , stdout, stderr = conn.exec_command("sudo apt-get install -y git")
    
    print stdout.read()
    print stderr.read()
    
    stdin, stdout, stderr = conn.exec_command("git clone https://github.com/bigsea-ufcg/bigsea-monitor.git")
    
    print stdout.read()
    print stderr.read()
    
    stdin , stdout, stderr = conn.exec_command("cd bigsea-monitor; sudo ./setup.sh")


def main():

    config = ConfigParser.RawConfigParser()
    
    config.read("experiment.cfg")
    
    auth_url = config.get("os-auth", "auth_url")
    username = config.get("os-auth", "username")
    password = config.get("os-auth", "password")
    project_name = config.get("os-auth", "project_name")
    project_domain_name = config.get("os-auth", "project_domain_name")
    user_domain_name = config.get("os-auth", "user_domain_name")
    #key_name = config.get("os-auth", "key_name")
    
    #instance_name = config.get("os-instance", "name")
    #instance_flavor = config.get("os-instance", "flavor")
    #instance_image = config.get("os-instance", "image")
    #instance_key_path = config.get("os-instance", "key_path")
    #instance_user = config.get("os-instance", "user")
    
    os = OpenStackUtils()
    
    nova = os.get_nova_client(auth_url=auth_url, username=username, password=password, 
                       project_name=project_name, project_domain_name=project_domain_name, user_domain_name=user_domain_name)
    
    start_scaler(os, nova)
    start_monitor(os, nova)
    
    #stdin , stdout, stderr = conn.exec_command("git clone https://github.com/bigsea-ufcg/bigsea-monitor.git")
    
    #print stdout.read()
    #print stderr.read()
    
    #os.delete_instance(nova, instance_id)
    
main()


