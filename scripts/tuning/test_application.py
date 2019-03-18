#!/usr/bin/python

import math
import time
import signal
import time
import sys

class GracefulKiller:
    kill_now = False
    def __init__(self):
        signal.signal(signal.SIGINT, self.exit_gracefully)
        signal.signal(signal.SIGTERM, self.exit_gracefully)

    def exit_gracefully(self,signum, frame):
        self.kill_now = True

task_count = 0
out = open("task.log.tmp", "w")
n = int(sys.argv[1])

if __name__ == '__main__':
    killer = GracefulKiller()

    while True:
        start_time = time.time()
        math.factorial(n)
        end_time = time.time()
        diff = end_time - start_time
        task_count += 1
        out.write(str(time.time()) + "," + str(1/diff) + "," + str(task_count) + "\n")

        if killer.kill_now:
            out.flush()
            out.close()
            break

