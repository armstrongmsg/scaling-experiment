#!/usr/bin/python

import sys
import random

def generate_workload(output_file, factorial_ns, reps, random_delta):
    output = open(output_file, "w")
     
    for i in xrange(len(factorial_ns)):
        rep = reps[i]

        for j in xrange(rep):
            n = random.randint(factorial_ns[i] - random_delta,
                               factorial_ns[i] + random_delta)
            output.write("%d\n" % n)

    output.close()

if __name__ == '__main__':
 
    output_file = sys.argv[1]
    random_delta = int(sys.argv[2])
    factorial_ns = []
    reps = []

    for i in xrange(3, len(sys.argv), 2):
        factorial_n = int(sys.argv[i])
        rep = int(sys.argv[i + 1])
        factorial_ns.append(factorial_n)
        reps.append(rep)

    generate_workload(output_file, factorial_ns, reps, random_delta)

