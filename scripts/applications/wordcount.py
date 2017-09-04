import sys
import os
import logging
import datetime
import threading
import time
from threading import Lock

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
    def __init__(self, words_files_directory, buffer_max_size, n_threads, log_file_path):
        self.completed_tasks = 0
        self.words_files_lock = Lock()
        self.words_files_directory = words_files_directory
        self.buffer_max_size = buffer_max_size
        self.n_threads = n_threads
        self.words_by_thread = []
        self.progress_by_thread = []
        
        self.words_file_names = os.listdir(words_files_directory)
        self.total_number_of_tasks = len(self.words_file_names)
        
        self.logger = Log("progress_log", log_file_path)
        configure_logging()
    
    def _count_words_in_file(self, words_file_name, words, buffer_max_size):
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
    
    def _count_thread(self, thread_index, words_file_names):
        _words = self.words_by_thread[thread_index]        
        
        try:
            while True:
                with self.words_files_lock:
                    word_file = words_file_names.pop(0)
                self._count_words_in_file(word_file, _words, self.buffer_max_size)
                
                self.progress_by_thread[thread_index] += 1
        except:
            print "No files to process"
    
    def _log_progress(self, completed_tasks):
        progress = completed_tasks/float(self.total_number_of_tasks)
        timestamp = datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S.%fZ')
        self.logger.log("[%s][Progress]: #%f" % (timestamp, progress))
    
    def _wait_for_completion(self):
        completed_tasks = 0
        
        while completed_tasks < self.total_number_of_tasks:
            completed_tasks = 0

            for i in xrange(self.n_threads):
                completed_tasks += self.progress_by_thread[i]
            
            self._log_progress(completed_tasks)
            time.sleep(1)
        
        self._log_progress(completed_tasks)
    
    def count(self):
        # Create and start threads
        for i in xrange(self.n_threads):
            self.words_by_thread.append({})
            self.progress_by_thread.append(0)
            thread = threading.Thread(target=self._count_thread, args=(i, self.words_file_names))
            thread.start()

        # Wait until threads finish counting
        self._wait_for_completion()

        # Aggregate results
        words_results = {}
        
        for sub_result in self.words_by_thread:
            for word in sub_result.keys():
                if not words_results.has_key(word):
                    words_results[word] = 0
                words_results[word] += sub_result[word]
        
        print words_results
        

if __name__ == '__main__':
    words_files_directory = sys.argv[1]
    buffer_max_size = int(sys.argv[2])
    n_threads = int(sys.argv[3])
    log_file_path = sys.argv[4]
    
    wc = WordCount(words_files_directory, buffer_max_size, n_threads, log_file_path)
    
    wc.count()
