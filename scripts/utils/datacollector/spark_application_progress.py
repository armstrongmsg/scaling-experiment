# Copyright (c) 2017 LSD - UFCG.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import requests
import sys

class SparkApplicationProgress:

    def __init__(self, master_ip, app_id, total_tasks):
        self.master_ip = master_ip
        self.app_id = app_id
        self.total_tasks = total_tasks

    def _get_progress(self, job_request):
        if total_tasks < 0:
            for result in job_request.json():
                progress = result['numCompletedTasks'] / float(result['numTasks'])
                progress = float("{:10.4f}".format(progress))
        else:
            completed_tasks = 0
 
            for i in xrange(len(job_request.json())):
                completed_tasks += job_request.json()[i]['numCompletedTasks']
 
            progress = completed_tasks/float(total_tasks)
            
        return progress

    def get_application_progress(self):
        try:
            job_request = requests.get('http://' + self.master_ip + ':4040/api/v1/applications/' + self.app_id + '/jobs')    
            return self._get_progress(job_request)
        except Exception as ex:
            print >> sys.stderr, ex.message
            raise
        
if __name__ == '__main__':
    master_ip = sys.argv[1]
    app_id = sys.argv[2]
    total_tasks = int(sys.argv[3])

    progress_collector = SparkApplicationProgress(master_ip, app_id, total_tasks)
    print progress_collector.get_application_progress()