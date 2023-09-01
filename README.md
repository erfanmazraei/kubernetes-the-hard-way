
# Kubernetes the Hard Way

This project is a step-by-step guide to setting up a Kubernetes cluster from scratch, without using any automation tools. It is intended for users who want to gain a deeper understanding of how Kubernetes works under the hood.

## Introduction

Kubernetes is a powerful container orchestration system that can be used to manage large-scale containerized applications. However, setting up a Kubernetes cluster can be a complex and daunting task, especially for users who are new to the system.

Kubernetes the Hard Way is a guide that walks you through the process of setting up a Kubernetes cluster from scratch, without using any automation tools. By following this guide, you will gain a deep understanding of how Kubernetes works and how to set it up manually.

##  Why Use Kubernetes the Hard Way?

This project is very useful for learning Kubernetes. By following this guide, you will gain a deep understanding of how Kubernetes works and how to set it up manually. This knowledge will be useful for troubleshooting and debugging Kubernetes issues, as well as for understanding how to customize Kubernetes to fit your specific needs.

## Prerequisites

Before you begin, you will need the following:

- Basic knowledge of Linux command line: You should be comfortable working with the Linux command line, as many of the tasks in this guide require you to use the command line.
- Basic knowledge of networking: You should have a basic understanding of networking concepts, such as IP addresses, subnets, and routing.

## Getting Started

To get started, follow these steps:

1. Clone this repository to your local machine:

```
git clone https://github.com/erfanmazraei/kubernetes-the-hard-way.git
```

2. Follow the steps in the `bash-setup` directory to set up your environment. This directory contains a set of Bash scripts that automate the process of setting up your environment for the rest of the guide.

3. Follow the steps in the `01-prerequisites` directory to set up the prerequisites for your Kubernetes cluster. This directory contains instructions on how to set up a Google Cloud Platform project, create a service account, and configure your local environment to use the Google Cloud SDK.

4. Follow the steps in the `02-certificate-authority` directory to create a certificate authority for your Kubernetes cluster. This directory contains instructions on how to create a private key and a self-signed root certificate that you will use to sign other certificates for your Kubernetes cluster.

5. Follow the steps in the `03-kubernetes-configuration-files` directory to create the configuration files for your Kubernetes cluster. This directory contains instructions on how to create the Kubernetes configuration files that define the components of your Kubernetes cluster, such as the API server, the controller manager, and the scheduler.

6. Follow the steps in the `04-data-encryption-keys` directory to create the data encryption keys for your Kubernetes cluster. This directory contains instructions on how to create the encryption keys that will be used to encrypt sensitive data in your Kubernetes cluster, such as secrets and config maps.

7. Follow the steps in the `05-bootstrapping-etcd` directory to set up the etcd cluster for your Kubernetes cluster. This directory contains instructions on how to set up a three-node etcd cluster that will be used to store the state of your Kubernetes cluster.

8. Follow the steps in the `06-bootstrapping-kubernetes-controllers` directory to set up the Kubernetes control plane for your Kubernetes cluster. This directory contains instructions on how to set up the Kubernetes control plane components, such as the API server, the controller manager, and the scheduler.

9. Follow the steps in the `07-bootstrapping-kubernetes-workers` directory to set up the Kubernetes worker nodes for your Kubernetes cluster. This directory contains instructions on how to set up the Kubernetes worker nodes that will run your containerized applications.

10. Follow the steps in the `08-configuring-kubectl` directory to configure the `kubectl` command-line tool for your Kubernetes cluster. This directory contains instructions on how to configure the `kubectl` tool to communicate with your Kubernetes cluster.

## Conclusion

Congratulations! You have now set up a Kubernetes cluster from scratch using Kubernetes the Hard Way. This guide has given you a deep understanding of how Kubernetes works and how to set it up manually. You can now use this knowledge to troubleshoot and debug Kubernetes issues, as well as to customize Kubernetes to fit your specific needs.

Note: This project is implemented with different programming languages. For now, the bash-setup directory contains Bash scripts that you can use to install Kubernetes step by step using Bash. However, you can adapt this guide to work with other programming languages as well.

For more information on Kubernetes, see the official Kubernetes documentation at https://kubernetes.io/docs/.
