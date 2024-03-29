import argparse
import re
import sys

parser = argparse.ArgumentParser("simple_example")
parser.add_argument("-e", "--each", help="The number of test case used to split the MCO test cases.", type=int, default=10)
parser.add_argument("file", nargs='?', type=argparse.FileType('r'), default=sys.stdin)
args = parser.parse_args()

num_tests = args.each
file = args.file

print("Splitting MCO execution to launch {0} tests in each execution", num_tests)

print("{0}", args)

count = 0
tests_batch = []
# Strips the newline character
for line in file.readlines():
    if line.strip("\n ") == "":
        continue
    count+=1
    result = re.search(r".+-(\d+)-.+", line)
    tc = result.group(1)
    tests_batch.append(tc)
    if len(tests_batch) == num_tests:
        print("|".join(tests_batch))
        tests_batch = []

print("|".join(tests_batch))
print("Total: {0} test cases".format(count))
file.close()
