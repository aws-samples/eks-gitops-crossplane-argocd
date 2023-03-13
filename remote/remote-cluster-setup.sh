kubectl get ns --kubeconfig ./kubeconfig-admin

#
# Create the service account and related artifact in the remote cluster
#
kubectl --kubeconfig ./kubeconfig-adminapply -f service-account-remote.yaml

#
# Check if the artifacts were created properly
#
kubectl --kubeconfig ./kubeconfig-admin -n kube-system get sa argocd-manager -o yaml
kubectl --kubeconfig ./kubeconfig-admin -n kube-system get secret argocd-manager -o yaml

#
# Create a Secret in the local cluster where Argo CD runs, that container the credentials of the above service account
#
kubectl apply -f cluster-secret.yaml

