#!/bin/bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/kubernetes/v1.21.0-beta.0/cluster/addons/metrics-server/autoscaling/v2beta2/custom-metrics.yaml
for file in *.yaml *.yml; do
  kubectl apply -f "$file"
done
