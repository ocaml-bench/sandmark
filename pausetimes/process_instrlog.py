from intervaltree import IntervalTree, Interval
import sys
import subprocess
import json
import os

bench_name = os.path.basename(sys.argv[1]).replace('.pausetimes_trunk.bench','')
instr_file = sys.argv[2]

def distribution(l):
  to_indices = []
  percentages = [10,20,30,40,50,60,70,80,90,95,99,99.9]
  for p in percentages:
    i = int(round(float(len(l))*float(p)/100.0-1,0))
    to_indices.append(i)
  i = 0
  distr = []
  while (i < len(percentages)):
    if (to_indices[i] == -1):
      distr.append(0)
    else:
      distr.append(l[to_indices[i]])
    i+=1

  return distr

def main():
  t = IntervalTree()

  with open(instr_file) as f:
    for l in f:
      l = l.strip()
      if (l.endswith("@") or l.endswith("#") or l.startswith("==")):
        continue
      words = l.split()
      if (words[1] != words[2]):
        t[int(words[1]):int(words[2])] = 0

  t.merge_overlaps()
  sorted_latencies = sorted(list(map(lambda x: x.end - x.begin, sorted(t))))

  if (len(sorted_latencies) > 0):
    max_latency = sorted_latencies[len(sorted_latencies) - 1]
    avg_latency = sum(sorted_latencies)/len(sorted_latencies)
  else:
    max_latency = 0
    avg_latency = 0

  distr = distribution(sorted_latencies)

  out = {}
  out["name"] = bench_name
  out["mean_latency"] = avg_latency
  out["max_latency"] = max_latency
  out["distr_latency"] = distr

  print(json.dumps(out))

main()
