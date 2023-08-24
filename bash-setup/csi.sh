#!/usr/bin/env bash


# First we try to install OpenEBS as our sci.
# make sure the iscsi is present and active on all worker nodes.
sudo apt-get update
sudo apt-get install open-iscsi
sudo systemctl enable --now iscsid

# Then we add the OpenEBS helm repo and update it.
helm repo add openebs https://openebs.github.io/charts
helm repo update

# Install with default settings.
helm install openebs --namespace openebs openebs/openebs --create-namespace

# Check needed pods are ready.
kubectl get pods -n openebs
# NAME                                           READY   STATUS    RESTARTS   AGE
# openebs-localpv-provisioner-56994674fb-7jvfj   1/1     Running   0          84s
# openebs-ndm-225jp                              1/1     Running   0          85s
# openebs-ndm-87s8h                              1/1     Running   0          85s
# openebs-ndm-k2gdj                              1/1     Running   0          85s
# openebs-ndm-operator-6ddf4497b6-thfvz          1/1     Running   0          84s

# Check installed storage class.
kubectl get sc
# NAME               PROVISIONER        RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
# openebs-device     openebs.io/local   Delete          WaitForFirstConsumer   false                  92s
# openebs-hostpath   openebs.io/local   Delete          WaitForFirstConsumer   false                  92s

# Create persistent volume claim and use it for pod.
vim pvc.yaml
vim foo.yaml
kubectl apply -f pvc.yaml
kubectl apply -f foo.yaml

# Now we see that the pvc is created and attached to pod.
kubectl get pvc
# NAME   STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS       AGE
# foo    Bound    pvc-c79ef5a0-a2be-4528-a64d-4232c2844ba0   1Gi        RWO            openebs-hostpath   16m

# Now we exec to pod and create a file on mounted volume.
kubectl exec -it foo -- sh
# touch /data/something

#### Now on the host we see that the file is created on the related directories.
# root@k8s-node3:/var/lib/kubelet/pods/6599a7a3-11ab-4644-a34f-19cb75f26a4b# ls -lhAF volumes/kubernetes.io~local-volume/pvc-c79ef5a0-a2be-4528-a64d-4232c2844ba0/
# total 0
# -rw-r--r-- 1 root root 0 Aug  4 22:42 something
# root@k8s-node3:/var/lib/kubelet/pods/6599a7a3-11ab-4644-a34f-19cb75f26a4b# ls -lhAF /var/openebs/local/pvc-c79ef5a0-a2be-4528-a64d-4232c2844ba0/
# total 0
# -rw-r--r-- 1 root root 0 Aug  4 22:42 something


###### The other sci plugins are not tested because of problems we have between api-server and pod network and DNS resolution of them
###### based on design of different controller nodes with out any network or dns between them. we try them in other versions of k8s.
