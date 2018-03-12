#!/usr/bin/python

import sys
import datetime
import logging
import os

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

def log_progress(logger, total_number_of_tasks, completed_tasks):
    progress = completed_tasks/float(total_number_of_tasks)
    timestamp = datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S.%fZ')
    logger.log("[%s][Progress]: #%f" % (timestamp, progress))

def get_base_data(size):
    string = "aaaaaaaaaa"
    base_data = ""    

    for i in xrange(100*size):
        base_data += string

    return base_data

if __name__ == '__main__':
    args = sys.argv
    file_sizes = []
    number_of_files = []
    logger = Log("progress_log", args[1])
    configure_logging()
    base_path = args[2]
    
    # in KB
    block_size = 1000
    total_number_of_tasks = 0
    completed_tasks = 0
    
    for i in xrange(3, len(args), 2):
        file_size = int(args[i])
        n_files = int(args[i + 1])
        file_sizes.append(file_size)
        number_of_files.append(n_files)
        total_number_of_tasks += n_files*2
        
    base_data = get_base_data(block_size) 
    
    for i in xrange(len(file_sizes)):
        file_size = file_sizes[i]
        n_files = number_of_files[i]
    
        for n in xrange(n_files):
            filename = "%s/%d.%d.%d.data" % (base_path, i, file_sizes[i], n)
            output_file = open(filename, "w")
    
            for k in xrange(file_size/block_size):
                output_file.write(base_data)
    
            completed_tasks += 1
            log_progress(logger, total_number_of_tasks, completed_tasks)
    
            output_file.close()
    
    for i in xrange(len(file_sizes)):
        file_size = file_sizes[i]
        n_files = number_of_files[i]
    
        for n in xrange(n_files):
            filename = "%s/%d.%d.%d.data" % (base_path, i, file_sizes[i], n)
            output_file = open(filename, "r")
    
            for k in xrange(file_size/block_size):
                output_file.read(block_size)
    
            completed_tasks += 1
            log_progress(logger, total_number_of_tasks, completed_tasks)
    
            output_file.close()
    
    for i in xrange(len(file_sizes)):
        file_size = file_sizes[i]
        n_files = number_of_files[i]
    
        for n in xrange(n_files):
            filename = "%s/%d.%d.%d.data" % (base_path, i, file_sizes[i], n)
            os.remove(filename)
