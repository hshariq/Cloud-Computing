# GenAI Troubleshooting Log

Q2 Selection of VNF(s) and Justification

Firstly for my responses fine tuning:
My response:
For the VNF I have selected a nginx load balancer, the constraints set by the coruswork suggested us to choose a VNF that is not more than 2 GB RAM hence the load balancer felt like the most effecient pick in this regard.
It is immensely suitable for the telecom scenrarios since it is used in telco/edge use cases. It operates between layer 4 and layer 7, and supports for telecom relavant protocols like GTP, SCTP and SRv6. 
Secondly the resource requirements are also met as I have configured a load balancer that has: 512Mi RAM and 0.5 CPU.
More importantly, it is kubernetes native, it works as a service type loadbalancer, and can easily be deployed on both full K8s (minikube) and on lightweight edge deployments like K3s. 
And lastly, and the reason it makes it the perfect fit for my coursework; the same VNF can be deployed both on edge and cloud. One set of manifests and configs can be used for both cloud like and edge like enviornments. 
On the contrary, I also explored full 5G cores like Free5GC / Open5GS, but they both are full 5G core stacks. And full deployments typically need 4 GB+ RAM and multiple cores across several pods.  
So for a <2 GB and single-CPU constraint, a telco-oriented load balancer is a justified and practical choice.

Then I asked copilot to refine it and give it a better structure:
I selected an nginx-based load balancer VNF (deployed as a Kubernetes Deployment exposed via a Service of type LoadBalancer). The coursework constraint (<2 GB RAM, single-CPU) favours a lightweight VNF with predictable performance; nginx is widely used in production for traffic steering and request distribution, making it an appropriate VNF analogue for NFV/MEC scenarios.

Suitability for Telecom Scenarios:
In NFV and MEC architectures, load balancing is a core network function used to distribute traffic across replicated network services and edge applications, improving availability, scalability, and latency. While this implementation focuses on HTTP/L7 traffic (sufficient for validating a service chain and generating repeatable load), the same architectural role maps to telecom deployments where traffic steering is required between service instances at the edge.

Resource Requirements & Justification:
The VNF sits in front of two backend “Hello World” service replicas and forwards requests to the backend Service, allowing end-to-end measurement of latency/throughput under load. I configured conservative Kubernetes limits of 512 MiB RAM and 0.5 vCPU for the load balancer, keeping the footprint well below the 2 GB limit and representative of constrained edge nodes.

Architectural Versatility:
it is deployed as a standard Deployment/Service and exposed via a Service of type LoadBalancer, so the same manifests can be applied to both Minikube (cloud-like) and K3s (edge-like)

Comparative Analysis:
I considered Free5GC/Open5GS, but full core deployments typically require multiple components (AMF/SMF/UPF, etc.), several pods, and often 4 GB+ RAM and multiple cores, which conflicts with the assignment constraints. Therefore, a lightweight load balancer VNF provides a practical, scientifically comparable workload for cloud vs edge evaluation.



Q3 Environment Setup (Cloud vs Edge) & Deployment of VNF(s)
I want u to write the above answer:

for all results u might have gotten answers:

But for challengeS:

I faced a couple of challenges, firslty how to deploy my cloud setup, i had to use my infrastructure as code skills, i first had to go through and understand how i can set up my minicube isntnacw, this was something that i did not really had a lot of kmnowsldeg of but using multiple online reousrces i came across how i can set it up on a docker instnace, i set it all up using terminal commands which was a huge new learnign for me, no need to ssh into an instance or anythig, open my instnce and run it



then for my edge instnace, i had to find a free to use reeosurce and muliplass was a big win for me, it was also pretty straightforward to set up, but once all ports and names of contianers were set, then i was able to deply it using my yaml files, finding the exact names, configurations were somethign that i had to really dive deep in a



moreover i used same hello wolrd and load balncer configs sp thart ican easily generatr copmarisons between both



then the biggest challenge for me was how i can automate the pipeline, intially i was starting the VM or docker contianer manually and running it one step by one eahc manually, but i wanted to come up with a script that does all of tjhsi manually, this is where i sarted writing my run.sh script which first does checks if containers are up and running, again this was challneging to figure out but as i further dived into the infrasturcure i figruee that simple commands and port identificationwas enough to do these codnitional checkings, if they were on, then move forward if not on then it will set up adns tart the contianeers and once staerted, deploy rhte vnf and hello world files and once all depluyment done it runs the test python file



testing for it was sliglhty tricky not a 100% sure of how to do it, used AI to research and help me find the best way to generate auto traffic and then i started getting reuslts:

And asked it to fix it and write in the better way:
Experimental Setup and Design:
The experiment is designed as a Comparative Performance Analysis between two distinct NFVi (Network Function Virtualization Infrastructure) tiers: a Cloud-like tier (Minikube/Docker) and a resource-constrained Edge-like tier (K3s/Multipass VM). To ensure a controlled environment, both tiers ran an identical Nginx Load Balancer VNF with resources capped at 512Mi RAM and 0.5 vCPU.The "Independent Variable" is the infrastructure type (OS-level vs. Hardware-level virtualization), while the "Dependent Variables" are the resulting network and resource metrics. The experiment utilized a Steady-State Load Test of 30 seconds with 4 concurrent worker threads to simulate consistent telecommunications traffic.Performance Metrics and Collection Methodology:Data was obtained through a custom-built, multi-threaded Python testing harness that synchronized traffic generation with infrastructure monitoring. Four key metrics were captured:Throughput (req/s): The rate of successful HTTP transactions processed by the VNF. The generate_traffic.py script calculated both "Attempted" and "Successful" throughput to identify the saturation point.Latency Percentiles (ms): Detailed latency profiles (Mean, P50, and P95) were measured to evaluate the "jitter" and responsiveness of the VNF under load.CPU Utilization: Measured in millicores using collect_metrics.py, which polled the Kubernetes Metrics Server via kubectl top pods every 5 seconds.Memory Consumption: Measured in MiB to monitor the VNF's stability within its 512Mi limit during high-traffic bursts.Monitoring and Validation Tools:Testing Harness: The run_experiment.py script utilized Python threading to run the traffic generator and metrics collector simultaneously, ensuring that resource spikes were directly correlated to network load.Access Abstraction: Since local macOS clusters lack native LoadBalancer IPs, a "detached" port-forwarding logic was implemented in test-lb-and-traffic.sh to provide a stable 9080/8080 gateway for the Python client.Lifecycle Validation: Before each run, kubectl rollout status verified the VNF's "Ready" state, ensuring that deployment overhead did not contaminate the performance results.


Q4 Experimental Design and Performance Monitoring
No external IP; starting port-forward on 9080...

=== 1. Curl LB (Hello World) ===
Hello from Cloud VNF demo


=== 2. Generate traffic (30s) ===
Traffic run results:
  URL: http://127.0.0.1:9080
  Duration: 30 s
  Total requests: 18188 (ok: 16292, errors: 1896)
  Throughput (attempted): 606.27 req/s
  Throughput (successful): 543.07 req/s
  Latency (ms) — mean: 7.18, p50: 4.95, p95: 26.91, min: 3.21, max: 630.04
hamza.shariq@PRLX00325 Cloud Computing % ./scripts/stop-all.sh

hamza.shariq@PRLX00325 Cloud Computing % ./scripts/deploy/test-lb-and-traffic.sh edge 30
No external IP; starting port-forward on 9080...

=== 1. Curl LB (Hello World) ===
Hello from Edge VNF demo


=== 2. Generate traffic (30s) ===
Traffic run results:
  URL: http://127.0.0.1:9080
  Duration: 30 s
  Total requests: 55269 (ok: 16331, errors: 38938)
  Throughput (attempted): 1842.3 req/s
  Throughput (successful): 544.37 req/s
  Latency (ms) — mean: 3.51, p50: 3.22, p95: 5.11, min: 1.91, max: 51.48

Asked my LLM to help me with the generate traffic scripts and how and what are the best betrics to collect so I gave all of this information to my LLM and asked to rrefine my answer:
Experimental Setup and Design:
The experiment is designed as a Comparative Performance Analysis between two distinct NFVi (Network Function Virtualization Infrastructure) tiers: a Cloud-like tier (Minikube/Docker) and a resource-constrained Edge-like tier (K3s/Multipass VM). To ensure a controlled environment, both tiers ran an identical Nginx Load Balancer VNF with resources capped at 512Mi RAM and 0.5 vCPU.
The "Independent Variable" is the infrastructure type (OS-level vs. Hardware-level virtualization), while the "Dependent Variables" are the resulting network and resource metrics. 

The experiment utilized a Steady-State Load Test of 30 seconds with 4 concurrent worker threads to simulate consistent telecommunications traffic.

Performance Metrics and Collection Methodology:
Data was obtained through a custom-built, multi-threaded Python testing harness that synchronized traffic generation with infrastructure monitoring. Four key metrics were captured:
1) Throughput (req/s): The rate of successful HTTP transactions processed by the VNF. The generate_traffic.py script calculated both "Attempted" and "Successful" throughput to identify the saturation point.
2) Latency Percentiles (ms): Detailed latency profiles (Mean, P50, and P95) were measured to evaluate the "jitter" and responsiveness of the VNF under load.
3) CPU Utilization: Measured in millicores using collect_metrics.py, which polled the Kubernetes Metrics Server via kubectl top pods every 5 seconds.
4) Memory Consumption: Measured in MiB to monitor the VNF's stability within its 512Mi limit during high-traffic bursts.

Monitoring and Validation Tools:Testing Harness: The run_experiment.py script utilized Python threading to run the traffic generator and metrics collector simultaneously, ensuring that resource spikes were directly correlated to network load.Access Abstraction: Since local macOS clusters lack native LoadBalancer IPs, a "detached" port-forwarding logic was implemented in test-lb-and-traffic.sh to provide a stable 9080/8080 gateway for the Python client.Lifecycle Validation: Before each run, kubectl rollout status verified the VNF's "Ready" state, ensuring that deployment overhead did not contaminate the performance results.

Managing KUBECONFIG contexts was a key hurdle; Edge tests initially failed by targeting the Cloud. I resolved this by automating exports in the pipeline to ensure the CLI pointed to the correct VIM before execution.


Q5 Results and Discussion
Cloiud:
python3 scripts/monitoring/run_experiment.py --url http://127.0.0.1:9080 --duration 30 --out-dir results/cloud
[2026-03-20T00:11:05Z] sample 1/6 — pods: 3, total CPU: 2m, total memory: 21Mi
[2026-03-20T00:11:10Z] sample 2/6 — pods: 3, total CPU: 2m, total memory: 21Mi
[2026-03-20T00:11:16Z] sample 3/6 — pods: 3, total CPU: 2m, total memory: 21Mi
[2026-03-20T00:11:21Z] sample 4/6 — pods: 3, total CPU: 2m, total memory: 21Mi
[2026-03-20T00:11:26Z] sample 5/6 — pods: 3, total CPU: 2m, total memory: 21Mi
[2026-03-20T00:11:31Z] sample 6/6 — pods: 3, total CPU: 2m, total memory: 21Mi

--- Experiment summary ---
Traffic: {'url': 'http://127.0.0.1:9080', 'duration_sec': 30, 'total_requests': 16233, 'successful_requests': 16233, 'errors': 0, 'throughput_total_rps': 541.1, 'throughput_success_rps': 541.1, 'latency_mean_ms': 7.39, 'latency_p50_ms': 4.9, 'latency_p95_ms': 32.03, 'latency_min_ms': 2.94, 'latency_max_ms': 180.9}
Metrics: 6 samples written to results/cloud/metrics_experiment.csv
Traffic stats: results/cloud/traffic_experiment.json

python3 scripts/monitoring/run_experiment.py --url http://127.0.0.1:9080 --duration 30 --out-dir results/edge
[2026-03-20T00:16:08Z] sample 1/6 — pods: 3, total CPU: 1m, total memory: 17Mi
[2026-03-20T00:16:13Z] sample 2/6 — pods: 3, total CPU: 1m, total memory: 17Mi
[2026-03-20T00:16:19Z] sample 3/6 — pods: 3, total CPU: 0m, total memory: 17Mi
[2026-03-20T00:16:24Z] sample 4/6 — pods: 0, total CPU: 0m, total memory: 0Mi
[2026-03-20T00:16:29Z] sample 5/6 — pods: 0, total CPU: 0m, total memory: 0Mi
[2026-03-20T00:16:34Z] sample 6/6 — pods: 0, total CPU: 0m, total memory: 0Mi

--- Experiment summary ---
Traffic: {'url': 'http://127.0.0.1:9080', 'duration_sec': 30, 'total_requests': 61092, 'successful_requests': 16328, 'errors': 44764, 'throughput_total_rps': 2036.4, 'throughput_success_rps': 544.27, 'latency_mean_ms': 3.68, 'latency_p50_ms': 3.31, 'latency_p95_ms': 5.35, 'latency_min_ms': 1.54, 'latency_max_ms': 71.32}
Metrics: 6 samples written to results/edge/metrics_experiment.csv


I can see latency has a winner of edge, but we can see that it runs into many errors, whereas cloud which is slightly slower it still ensures low on error counts. This shows that cloud is not big on dropping packets, this could be clealry bcuz since the container utilizing the docker infra hence leading to no overhead, but with edge due to manamgnet of mulitple nodes and virtulization overhead we see loss of packets
Shared this and the json files with the AI and asked it refine my answer:

1. Comparative Performance DataMetricCloud (Minikube / Docker)Edge (K3s / Multipass VM)Successful Throughput$541.1$ req/s$544.27$ req/sAttempted Throughput$541.1$ req/s$2036.4$ req/sSuccess Rate$100\%$ ($0$ errors)$\approx 26.7\%$ ($44,764$ errors)Mean Latency$7.39$ ms$3.68$ msP95 Latency$32.03$ ms$5.35$ msPeak CPU Usage$2$m ($0.002$ cores)$1$m ($0.001$ cores)Peak Memory Usage$21$ MiB$17$ MiB

Discussion of ResultsThe experimental data reveals a fundamental trade-off between OS-level virtualization (Cloud) and Hardware-level virtualization (Edge). The Cloud-like environment demonstrated high reliability, maintaining a 100% success rate across all requests. Conversely, the Edge-like environment exhibited a "Saturation Paradox": while its mean latency ($3.68$ ms) was significantly lower than the Cloud's ($7.39$ ms), it suffered a failure rate of over $73\%$ under the same worker load.





Q1 General information
Briefly describe your coursework. What have you done? 400 characters with spaces max.

My answer:
For my courswork I have found myself exploring the realms of infrastructure and shell scripts. A niche that I enjoyed a lot!

I came across Kubernetes clusters for the very first time, and deployed them oncloud and edge like instances. I have also added batch scripts that automate the pipeline of running the deployments and getting them ready, while also testing the load balncer with a gen-traffic script.

Sent it to AI for refinement:
For this coursework, I explored the intersection of NFV infrastructure and automation. I provisioned Cloud (Minikube) and Edge (K3s) Kubernetes clusters from scratch using shell scripts. I developed an automated pipeline to deploy an Nginx VNF, orchestrated via custom Bash scripts and a Python-based traffic generator to analyze real-world performance trade-offs.


I also took help in toruble  shooting fro generater traffice and run expeirmients since I was struggling to set it up




