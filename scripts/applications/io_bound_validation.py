#!/usr/bin/python

import logging
import sys
import datetime
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

n = int(sys.argv[1])
block_size = int(sys.argv[2])
output_file_name = sys.argv[3]
log_file_name = sys.argv[4]

logger = Log("io.log", log_file_name)
configure_logging()

base = "aaaaaaaaaa"
string_to_write = ""

for i in xrange(block_size/10):
    string_to_write  += base

output_file = open(output_file_name, "w")

for i in xrange(n):
    output_file.write(string_to_write)

    progress = (i + 1)/float(n)
    timestamp = datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S.%fZ')
    logger.log("[%s][Progress]: #%f" % (timestamp, progress))

output_file.close()
os.remove(output_file_name)
