import sys
import os
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

class WordCount:
    def _count_for_file(self, words_file_name, words, buffer_max_size):
        words_file = open(os.path.join(words_files_directory, words_file_name), "r")
        line = words_file.readline()
        
        words_buffer = []
        
        while line != "":
            words_buffer.append(line.strip())
                
            if len(words_buffer) == buffer_max_size:
                for word in words_buffer:
                    if not words.has_key(word):
                        words[word] = 0
                    words[word] += 1
                words_buffer = []
                    
            line = words_file.readline()
        
        for word in words_buffer:
            if not words.has_key(word):
                words[word] = 0
            words[word] += 1
                
        words_file.close()    
    
    def count(self, words_files_directory, buffer_max_size):
        words_file_names = os.listdir(words_files_directory)
        total_number_of_tasks = len(words_file_names) 
        completed_tasks = 0
        logger = Log("progress_log", log_file_path)
        configure_logging()
        
        words = {}

        for words_file_name in words_file_names:
            self._count_for_file(words_file_name, words, buffer_max_size)
            completed_tasks += 1
            
            progress = completed_tasks/float(total_number_of_tasks)
            timestamp = datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S.%fZ')
            logger.log("[%s][Progress]: #%f" % (timestamp, progress))
        
        print words

if __name__ == '__main__':
    words_files_directory = sys.argv[1]
    buffer_max_size = int(sys.argv[2])
    log_file_path = sys.argv[3]
    
    wc = WordCount()
    
    wc.count(words_files_directory, buffer_max_size)
