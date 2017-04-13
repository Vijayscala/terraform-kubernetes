# terraform-kubernetes
An attempt to build a kubernetes cluster on AWS using CoreOs AMI

### What's working?
- Working Kubernetes Cluster
- Can set number of etcd/API/Worker nodes
- CA certs for API
- Configure local kubectl using generated certs (sh ./configure_kubectl)

### Still to do?
- Security
- High Availibility
- Code Clean Up


References:
- https://coreos.com/kubernetes/docs/latest/getting-started.html
- https://github.com/bakins/kubernetes-coreos-terraform
- https://github.com/Capgemini/tf_tls
