##!/bin/bash

#
# Install ArgoCD
#
kubectl create namespace argocd
kubectl apply -n argocd -f install.yaml

#
# By default, the Argo CD API server is not exposed with an external IP. It is deployed as a ClusterIP server. 
# The easiest way to expose it outside the cluster is to patch this Service as a 'LoadBalancer' type.
# Alternatively, an Ingress can be registered with an Ingress Controller so that we can use an existing Load Balancer.
# Optionally, Create a CNAME record pointing to the load balancer
#
kubectl -n argocd patch svc argocd-server -p '{"spec": {"type": "LoadBalancer"}}'

#
# Upon installation, a Secret named 'argocd-initial-admin-secret' is created which contains the base64-encoded password for 'admin' account.
# The next step is to change the default password for the admin account
# Following this, it is best to delete the 'argocd-initial-admin-secret' Secret
#
kubectl -n argocd get secret argocd-initial-admin-secret --template={{.data.password}} | base64 -D; echo
argocd login argocd.test.sarathy.io
argocd account update-password
kubectl -n argocd delete secret argocd-initial-admin-secret

#
# Apply general Argo CD configuration
#
kubectl apply -f argocd-setup-configmap.yaml

#
# ArgoCD will need to know the SSH known hosts public key of the repository servers.
# This information is provided using a ConfigMap named 'argocd-ssh-known-hosts-cm'
#
kubectl apply -f argocd-setup-ssh-known-hosts-configmap.yaml

#
# Setup Git and Helm repositories 
#
kubectl apply -f argocd-setup-git-repositories.yaml 
kubectl apply -f argocd-setup-helm-repositories.yaml 

#
# Setup Argo CD projects 
#
kubectl apply -f project-applications.yaml
kubectl apply -f project-workloads.yaml

#
# Deploy the Application that installs Crossplane and triggers the provisioning of an EKS cluster
#
argocd app create --file application-crossplane.yaml

#
# Deploy the App of Apps to the management cluster which will trigger the deployment of applications to the workload cluster
# Prior to doing this, you will have to register the remote workload cluster per the instructions here: 
# https://argo-cd.readthedocs.io/en/stable/getting_started/#5-register-a-cluster-to-deploy-apps-to-optional
#
argocd app create --file application-apps.yaml

  


