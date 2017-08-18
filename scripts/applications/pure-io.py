import os
import sys
import logging
import datetime

class Log:
    def __init__(self, name, output_file_path):
        self.logger = logging.getLogger(name)
        handler = logging.StreamHandler()
        handler.setLevel(logging.DEBUG)
        self.logger.addHandler(handler)
        handler = logging.FileHandler(output_file_path)
        self.logger.addHandler(handler)

    def log(self, text):
        self.logger.info(text)

def configure_logging():
    logging.basicConfig(level=logging.INFO)

def get_1kb_string():
    string = ""
    
    for i in xrange(100):
        string += BASE_DATA_STRING
        
    return string

def get_string(kbs):
    string = ""
    
    for i in xrange(kbs):
        string += get_1kb_string()
        
    return string

BASE_DATA_STRING = "aaaaaaaaaa"

if __name__ == '__main__':
    size = int(sys.argv[1])
    number_of_files = int(sys.argv[2])
    block_size = int(sys.argv[3])
    log_file_path = sys.argv[4]
    
    logger = Log("progress_log", log_file_path)
    configure_logging()
    
    data = get_string(block_size)
    total_number_of_tasks = 2*size*number_of_files/block_size
    completed_tasks = 0
    
    for filenumber in xrange(number_of_files):
        filename = "data." + str(filenumber)
        f = open(filename, "w")
        
        for i in xrange(size/block_size):
            f.write(data)
            completed_tasks += 1
            progress = completed_tasks/float(total_number_of_tasks)
            
            timestamp = datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S.%fZ')
            logger.log("[%s][Progress]: #%f" % (timestamp, progress))
    
        f.close()
    
    for filenumber in xrange(number_of_files):
        filename = "data." + str(filenumber)
        f = open(filename, "r")
        
        for i in xrange(size/block_size):
            
            f.read(block_size*1000)
            completed_tasks += 1
            progress = completed_tasks/float(total_number_of_tasks)
            
            timestamp = datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S.%fZ')
            logger.log("[%s][Progress]: #%f" % (timestamp, progress))
    
        f.close()
    
    for filenumber in xrange(number_of_files):
        filename = "data." + str(filenumber)
        os.remove(filename)
        