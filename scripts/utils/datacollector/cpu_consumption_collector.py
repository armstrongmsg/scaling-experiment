from monasca_monitor import Monasca_Monitor
import datetime
import time
import sys

class CPU_Usage:
    
    def __init__(self):
        self.mm = Monasca_Monitor()
    
    def get_cpu_usage(self, vm_id):
        measurement = self.mm.last_measurement('vm.cpu.utilization_norm_perc', {'resource_id':vm_id})
        return measurement[1]
    
    def get_cpu_usage_history(self, vm_id, start_time, end_time):
        start_time_str = datetime.datetime.fromtimestamp(int(start_time)).strftime('%Y-%m-%dT%H:%M:%S.0Z')
        all_measurements = self.mm.get_measurements('vm.cpu.utilization_norm_perc', {'resource_id':vm_id}, 
                                                start_time_str)
        
        usage = []
        for measurement in all_measurements:
            timestamp = float(time.mktime(datetime.datetime.strptime(measurement[0], "%Y-%m-%dT%H:%M:%S.%fZ").timetuple()))
            if timestamp >= float(start_time) and timestamp <= float(end_time):
                usage.append(measurement[1])
        
        return usage

if __name__ == "__main__":
    vm_id = sys.argv[1]
    start_time = sys.argv[2]
    end_time = sys.argv[3]
    
    cpu = CPU_Usage()
    history = cpu.get_cpu_usage_history(vm_id, start_time, end_time)
    history_str = ""
    
    if len(history) > 0:
        history_str += str(history[0])
        for i in xrange(1, len(history)):
            history_str += " " + str(history[i])
            
    print history_str
