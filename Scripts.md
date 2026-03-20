Cloud like- simple run:
./run
./scripts/deploy/test-lb-and-traffic.sh 30

Cloud like- experiment run
Make sure above is running
unset KUBECONFIG
Port fading: kubectl port-forward -n vnf-demo svc/vnf-nginx-lb 9080:80
python3 scripts/monitoring/run_experiment.py --url http://127.0.0.1:9080 --duration 30 --out-dir results/cloud


Make sure u stop: 
./scripts/stop-all.sh

Edge like- simple run:
./run-edge
./scripts/deploy/test-lb-and-traffic.sh edge 30

Edge like- experiment run
Make sure above is running
export KUBECONFIG=${HOME}/.kube/edge-k3s.yaml
Port fading: kubectl port-forward -n vnf-demo svc/vnf-nginx-lb 9080:80
python3 scripts/monitoring/run_experiment.py --url http://127.0.0.1:9080 --duration 30 --out-dir results/edge

