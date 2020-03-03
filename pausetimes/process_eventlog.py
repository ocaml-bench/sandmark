from intervaltree import IntervalTree, Interval
import sys
import subprocess
import json
import os

bench_name = os.path.basename(sys.argv[1]).replace('.pausetimes_multicore.bench','')
json_file = sys.argv[2]
summary = True if len(sys.argv) > 3 and sys.argv[3] == "summary" else False

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
  trees = {}
  with open(json_file) as f:
    data = json.load(f)
    stacks = {}
    for event in data["traceEvents"]:
      if (event["ph"] == "B"):
        key = str(event["pid"])+":"+str(event["tid"])
        ts = int(float(event["ts"])*1000.0)
        name = event["name"]
        if key in stacks:
          stacks[key].append((name,ts,0))
        else:
          stacks[key] = [(name,ts,0)]
      elif (event["ph"] == "E"):
        key = str(event["pid"])+":"+str(event["tid"])
        ts = int(float(event["ts"])*1000.0)
        name = event["name"]
        (nameStart, startTs, overhead) = stacks[key].pop()
        assert (nameStart == name)
        if not key in trees:
          trees[key] = IntervalTree()
        trees[key].addi(startTs, ts, {'name': name, 'overhead': overhead, 'tid': event["tid"]})
      elif (event["ph"] == "C" and event["name"] == "overhead#"):
        key = str(event["pid"])+":"+str(event["tid"])
        overhead = int(event["args"]["value"])
        l = []
        for e in stacks[key]:
          (name,ts,o) = e
          l.append((name,ts,o+overhead))
        stacks[key] = l

  latencies = []
  intervals = []

  for t in trees.values():
    domain_terminate_intervals = IntervalTree((i for i in t if i.data['name'].startswith("major_gc/finish_")))
    t.merge_overlaps((lambda acc,v: {'name': acc['name'], 'overhead': acc['overhead'] + v['overhead'], 'tid': acc['tid']}))
    latencies = latencies + list(map(lambda x: x.end - x.begin - x.data['overhead'], sorted(t - domain_terminate_intervals)))
    intervals.extend(t)
  sorted_latencies = sorted(latencies)

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

  if summary:
    sorted_intervals = sorted(intervals, key=lambda i: -(i.end - i.begin))

    for interval in sorted_intervals[0:32]:
      print(str(interval.end - interval.begin) + " " + str(interval))

main()
