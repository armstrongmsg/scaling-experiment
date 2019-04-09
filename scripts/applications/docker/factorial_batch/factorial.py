import math
import requests
import sys

url = sys.argv[1]
n = int(requests.get(url).text)

while n != -1:
    math.factorial(n)
    n = int(requests.get(url).text)

