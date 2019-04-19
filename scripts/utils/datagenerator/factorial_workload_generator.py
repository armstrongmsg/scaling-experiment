#!/usr/bin/python

import sys

def generate_workload(output_file, factorial_ns, reps):
    output = open(output_file, "w")
     
    for i in xrange(len(factorial_ns)):
        n = factorial_ns[i]
        rep = reps[i]

        for j in xrange(rep):
            output.write("%d\n" % n)

    output.close()

if __name__ == '__main__':
 
    output_file = sys.argv[1]
    factorial_ns = []
    reps = []

    for i in xrange(2, len(sys.argv), 2):
        factorial_n = int(sys.argv[i])
        rep = int(sys.argv[i + 1])
        factorial_ns.append(factorial_n)
        reps.append(rep)

    generate_workload(output_file, factorial_ns, reps)

