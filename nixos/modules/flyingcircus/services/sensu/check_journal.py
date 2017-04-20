#!/usr/bin/env python3

import re

print("Enter message:")
message = input()

m = None
while m is None:
    pattern = input("Pattern: ")
    try:
        m = re.search(pattern, message)
    except re.error as e:
        print(e)
    else:
        if m is None:
            print("No match")

print("match")
