# Problems

1. After installing calico on the cluster, we have this error when interacting with the cluster:

   ```bash
   E0729 09:02:24.426690  214106 memcache.go:287] couldn't get resource list for projectcalico.org/v3: the server is currently unable to handle the request
   E0729 09:02:24.635139  214106 memcache.go:121] couldn't get resource list for projectcalico.org/v3: the server is currently unable to handle the request
   E0729 09:02:24.847758  214106 memcache.go:121] couldn't get resource list for projectcalico.org/v3: the server is currently unable to handle the request
   E0729 09:02:25.092376  214106 memcache.go:121] couldn't get resource list for projectcalico.org/v3: the server is currently unable to handle the request
   NAME        STATUS   ROLES    AGE   VERSION
   k8s-node1   Ready    <none>   20h   v1.26.4
   k8s-node2   Ready    <none>   19h   v1.26.4
   k8s-node3   Ready    <none>   19h   v1.26.4
   ```

   The error comes from this section:

   ```bash
   mohammad@mohammad-Latitude-E7450:~/projects/ssboostan/kube-deep-dive$ kubectl get apiservices.apiregistration.k8s.io
   E0729 08:59:56.227485  213920 memcache.go:287] couldn't get resource list for projectcalico.org/v3: the server is currently unable to handle the request
   E0729 08:59:56.432299  213920 memcache.go:121] couldn't get resource list for projectcalico.org/v3: the server is currently unable to handle the request
   E0729 08:59:56.632230  213920 memcache.go:121] couldn't get resource list for projectcalico.org/v3: the server is currently unable to handle the request
   E0729 08:59:56.845955  213920 memcache.go:121] couldn't get resource list for projectcalico.org/v3: the server is currently unable to handle the request
   E0729 08:59:58.139595  213920 memcache.go:287] couldn't get resource list for projectcalico.org/v3: the server is currently unable to handle the request
   E0729 08:59:58.932120  213920 memcache.go:121] couldn't get resource list for projectcalico.org/v3: the server is currently unable to handle the request
   E0729 08:59:59.145889  213920 memcache.go:121] couldn't get resource list for projectcalico.org/v3: the server is currently unable to handle the request
   E0729 08:59:59.378416  213920 memcache.go:121] couldn't get resource list for projectcalico.org/v3: the server is currently unable to handle the request
   NAME                                    SERVICE                       AVAILABLE                      AGE
   v1.                                     Local                         True                           20h
   v1.admissionregistration.k8s.io         Local                         True                           20h
   v1.apiextensions.k8s.io                 Local                         True                           20h
   v1.apps                                 Local                         True                           20h
   v1.authentication.k8s.io                Local                         True                           20h
   v1.authorization.k8s.io                 Local                         True                           20h
   v1.autoscaling                          Local                         True                           20h
   v1.batch                                Local                         True                           20h
   v1.certificates.k8s.io                  Local                         True                           20h
   v1.coordination.k8s.io                  Local                         True                           20h
   v1.crd.projectcalico.org                Local                         True                           18h
   v1.discovery.k8s.io                     Local                         True                           20h
   v1.events.k8s.io                        Local                         True                           20h
   v1.networking.k8s.io                    Local                         True                           20h
   v1.node.k8s.io                          Local                         True                           20h
   v1.operator.tigera.io                   Local                         True                           18h
   v1.policy                               Local                         True                           20h
   v1.rbac.authorization.k8s.io            Local                         True                           20h
   v1.scheduling.k8s.io                    Local                         True                           20h
   v1.storage.k8s.io                       Local                         True                           20h
   v1alpha1.admissionregistration.k8s.io   Local                         True                           20h
   v1alpha1.internal.apiserver.k8s.io      Local                         True                           20h
   v1alpha1.networking.k8s.io              Local                         True                           20h
   v1alpha1.resource.k8s.io                Local                         True                           20h
   v1beta1.storage.k8s.io                  Local                         True                           20h
   v1beta2.flowcontrol.apiserver.k8s.io    Local                         True                           20h
   v1beta3.flowcontrol.apiserver.k8s.io    Local                         True                           20h
   v2.autoscaling                          Local                         True                           20h
   v3.projectcalico.org                    calico-apiserver/calico-api   False (FailedDiscoveryCheck)   18h
   ```

   How to fix this?

2. We don't have permissions to run ping on cri-o node. When we use CRI-O as our runtime, we don't have some capabilities.
   For solving these problems we should give the capabilities we need to the container using `securityContext`

   ```diff
   apiVersion: v1
   kind: Pod
   metadata:
   name: test
   spec:
   nodeName: k8s-node3
   containers:
      - name: test
         image: nginx:alpine
   +     securityContext:
   +     capabilities:
   +        add:
   +           - NET_RAW
   -
   ```

   The `NET_RAW` capability allows the container to create raw sockets. This is needed for the ping command to work.

we don't have dns server on worker node neither controller node.
I can't solve this problem until now on the k8s setup so I continue with flannel not calico and openEBS not longhorn.
also I ignore the error on config of IP pool of metallb with deleting the validation webhook of metallb.
This problems should not happen in normal setup of k8s that controller nodes has access to dns and pod network.
