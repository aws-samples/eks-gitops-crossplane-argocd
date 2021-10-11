## Amazon EKS cluser management with Crossplane and Argo CD

This Git repository contains software artifacts to deploy [Crossplane](https://crossplane.io/) server and [Argo CD](https://argoproj.github.io/argo-cd/) to an Amazon EKS cluster. Please refer to this accompanying blog post for details about how this works.

<img class="wp-image-1960 size-full" src="images/Deployment-Architecture.png" alt="Deployment architecture" width="854" height="527" />

### Solution overview

Here’s the high level overview of the solution architecture.

<ul>
  <li>
    Start off with an Amazon EKS cluster that was created using any one of the [approaches outlined here](https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html)
  </li>
  <li>
    Install Argo CD on this cluster to manage all deployment tasks and point it to a Git repository containing the deployment artifacts
  </li>
  <li>
    Deploy Crossplane components that are needed to manage the lifecycle of AWS managed service resources  
  </li>  
  <li>
    Deploy Crossplane-specific custom resources to provision an Amazon EKS cluster  
  </li> 
  <li>
    Deploy a set of workloads to the new cluster  
  </li> 
</ul>

The goal is to manage all of these tasks in a declarative style based on the [GitOps](https://www.weave.works/blog/what-is-gitops-really) approach.

### Deploy


### Cleanup


## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.
