##!/bin/bash

#
# The Crossplane CLI extends kubectl with functionality to build, push, and install Crossplane packages
#
curl -sL https://raw.githubusercontent.com/crossplane/crossplane/release-1.0/install.sh | sh
curl -sL https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh | sh
sudo mv kubectl-crossplane /usr/local/bin

#
# Install Crossplane on your "management" cluster
#
kubectl create namespace crossplane-system
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

#
# Install Crossplane core components using Helm chart
#
helm install crossplane --namespace crossplane-system crossplane-stable/crossplane --version 1.4.1

#
# Providers extend Crossplane with custom resources that can be used to declaratively configure a system. 
# In order to provision a resource, a CRD needs to be registered in your Kubernetes cluster and its controller should be watching the Custom Resources those CRDs define. 
# Crossplane provider packages contain many CRDs and their controllers.
# The 'provider-aws' package is the Crossplane infrastructure provider for AWS. This package contains the followig:
# 1. Custom Resource Definitions (CRDs) that model AWS infrastructure and services (e.g. RDS, S3, EKS clusters, etc.) These are called 'managed resources'
# 2. Controllers to provision these resources in AWS based on the users desired state captured in CRDs they create
# 3. Implementations of Crossplane's portable resource abstractions, enabling AWS resources to fulfill a user's general need for cloud services
#
# The core Crossplane controller can install provider controllers and CRDs for you through its own provider packaging mechanism, which is triggered by the application of a 'Provider' resource. 
# In order to request installation of the provider-aws package, apply the 'aws-provider.yaml' resource to the cluster where Crossplane is running.
# Providers can be installed using the 'kubectl crossplane install provider' command as well.
# Check out documentation on installing providers: https://crossplane.io/docs/v1.3/concepts/providers.html
#
kubectl apply -f aws-provider.yaml 

#
# In order to authenticate with the external provider API such as AWS, the provider controllers need to have access to credentials. 
# It could be an IAM User for AWS
# An AWS user with Administrative privileges is needed to enable Crossplane to create the required resources
# We wil have to first create a configuration file, secrets.conf, with credeantials of an AWS account in the following format.
#
# [default]
# aws_access_key_id =ABCDEFGHIJ0123456789
# aws_secret_access_key = Ow3HUaP8BbqkV4dUrZr0H7yT5nGP5OPFcZJ+
#
# Then using that file, a Kubernetes Secret is created as follows
#
kubectl -n crossplane-system create secret generic aws-credentials --from-file=credentials=./secrets.conf

#
# Create a ProviderConfig resource, referencing the above Secret
#
kubectl apply -f aws-providerconfig.yaml


#
# Crossplane goes beyond simply modelling infrastructure primitives as ‘managed resources’. 
# Composition is a concept that allows platform builders to define new custom resources that are composed of managed resources, like an RDS instance
# Crossplane calls these “composite resources” (XRs).
# Composition can be used to build a catalogue of custom resources and classes of configuration that fit the needs and opinions of your organisation. 
# Crossplane uses two special resources to define and configure these new composite resources:
# A CompositeResourceDefinition (XRD) defines a new kind of composite resource, including its schema. An XRD may optionally offer a claim (XRC).
# A Composition specifies which managed resources a composite resource will be composed of, and how they should be configured. 
# You can create multiple Composition options for each composite resource.
# Check out the composition documentation: https://crossplane.io/docs/v1.3/concepts/composition.html
#
# CompositeResourceDefinitions (XRDs) and Compositions may be packaged and installed as a configuration. 
# A configuration is a package of composition configuration that can easily be installed to Crossplane by creating a declarative 'Configuration' resource, or by using 'kubectl crossplane install configuration'.
# Check out the documentation on creating configuration: https://crossplane.io/docs/v1.3/getting-started/create-configuration.html
#

#
# Create a package for EKS cluster creation
# This package will help create a new VPC with 2 private/public subnets, IGW, NATGW and the EKS cluster with managed node group
# Push this package to a repository in an image registry
#
cd eks-configuration
kubectl crossplane build configuration
kubectl crossplane push configuration IMAGE_REPO:IMAGE_TAG


#
# Install the package to a cluster 
# Use one of the following two options to either install the one from the public repo in ECR and the one you built above.
#
kubectl apply -f crossplane-eks-composition.yaml
kubectl crossplane install configuration IMAGE_REPO:IMAGE_TAG

#
# Check if the package and the XRDs defined in it were installed properly
#
kubectl get Configuration crossplane-eks-composition
kubectl get CompositeResourceDefinition eksclusters.eks.sarathy.io

#
# Create an EKS cluster and a nodegroup using an XR
#
kubectl apply -f eks-cluster-xr.yaml

#
# Here are a set of CLI commands to look at various resources 
#
kubectl get crossplane  # get all resources related to Crossplane.
kubectl get managed     # get all resources that represent a unit of external infrastructure such as RDSInstance.
kubectl get composite   # get all resources that represent an XR


#
# Cleanup
#
kubectl delete -f crossplane-eks-composition.yaml
kubectl delete -f aws-providerconfig.yaml
kubectl delete -f aws-provider.yaml 
kubectl delete -f aws-credentials.yaml
helm uninstall crossplane --namespace crossplane-system

