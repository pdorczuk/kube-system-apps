# teleport

Files used to install and set up Teleport for secure access to both the host running kubeadm and the Kubernetes cluster used in this demo.

## Getting Started

This is designed to be a test/demo envrionment mostly for me to learn Kubernetes concepts, but 

### Prerequisites

You need a working Teleport proxy that is configured for Kubernetes authentication.

### Installing

I don't have a proper network-wide DNS set up so my first step is to add a static DNS entry in my cluster so that the Teleport pod knows how to reach the proxy server.
https://medium.com/@hjrocha/add-a-custom-host-to-kubernetes-a06472cedccb

```
kubectl -n kube-system edit cm coredns
```

Change
hosts custom.hosts <TELEPORT_URL> {
    <TELEPORT_IP> <TELEPORT_URL>
    fallthrough
}

Delete the CoreDNS pods so they reload the new configuration.
```
kubectl -n kube-system delete pod -l k8s-app=kube-dns
```

Run the get_kubeconfig.sh script which will set up RBAC inside the cluster and generate a kubeconfig file which will be used by Teleport clients.

```
bash get_kubeconfig.sh
```

Copy the kubeconfig file to whatever location is specified in your /etc/teleport.yaml file. In my case:

```
sudo cp kubeconfig /var/lib/teleport/kubeconfig
```
And finally deploy Teleport in the cluster.

```
kustomize build . | kubectl create -f-
```