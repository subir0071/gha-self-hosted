# gha-self-hosted

<!-- Execute the azure remote backend --> 
 act workflow_dispatch --input confirm="yes" -W .github/workflows/create_azure_remote_backend.yaml --secret-file secret.prop


<!-- Execute azure infra creation -->

act -W .github/workflows/deploy_azure_infra.yaml --secret-file secret.prop

<!-- Destroy Azure infra -->
act workflow_dispatch --input confirm="yes" -W .github/workflows/deploy_azure_infra.yaml --secret-file secret.prop

act -W .github/workflows/deploy_receiver_function.yml --secret-file secret.prop