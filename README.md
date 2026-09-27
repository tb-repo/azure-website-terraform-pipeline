# Azure Website Infrastructure and CI/CD

This project demonstrates an Infrastructure as Code and continuous delivery workflow for hosting a simple website on Microsoft Azure. Terraform defines the cloud resources, while Azure Pipelines automates validation, planning, infrastructure deployment, website delivery, and post-deployment checks.

The repository is intended as a learning reference. Review and adapt its resource names, locations, network ranges, identity, and backend settings before using it in another Azure subscription.

## Solution Overview

The reference design includes:

- An Azure virtual network divided into public and private subnets.
- Network security groups to control subnet traffic and a route table for explicit routing.
- A NAT Gateway and public IP for outbound connectivity from private resources.
- A Linux virtual machine running Nginx and serving the website.
- A public IP for web access. The example allows HTTP; production sites should use an appropriate TLS-enabled ingress design.
- Terraform state stored remotely in an Azure Storage blob, with Azure identity-based access.
- Azure Pipelines using a workload-identity-federated service connection instead of a long-lived Azure client secret.

The web VM is directly exposed in this learning design. For production, evaluate a managed web-hosting service or a protected ingress layer, enable HTTPS, restrict administration access, and apply organization security requirements. Network resources such as VMs, public IPs, and NAT Gateways can incur ongoing charges.

## Delivery Workflow

The intended automation flow is:

1. On a pull request, validate Terraform and website code, then generate a Terraform plan for review.
2. After merge, require the appropriate approval before applying the reviewed infrastructure changes.
3. Build and publish the website artifact, then deploy it to the web host.
4. Run a smoke test against the deployed site and publish the result with the pipeline run.
5. Keep destructive infrastructure teardown as a separate, explicitly approved operation.

The current `azure-pipelines.yml` provides Terraform formatting, initialization, validation, and planning on pushes to the configured branch. Infrastructure apply and independent website deployment are intended extensions to this workflow and should be protected with suitable reviews and approvals.

## Repository Organization

- `terraform/provider.tf` configures Terraform, the AzureRM provider, and the remote state backend.
- `terraform/network.tf` defines the virtual network, subnets, routing, security groups, public IPs, and NAT Gateway.
- `terraform/compute.tf` defines the network interface, Linux VM, SSH public-key lookup, and initial Nginx configuration.
- `azure-pipelines.yml` defines the CI validation and plan workflow.
- `.gitignore` excludes local Terraform working data, state artifacts, plans, and private key files.

All `.tf` files in `terraform/` form one Terraform root module. `.terraform.lock.hcl` should be committed so local and pipeline runs use consistent provider selections.

## Prerequisites

- An Azure subscription and permission to create the resources defined by the Terraform configuration.
- An existing resource group, or an intentional change to the Terraform configuration to create one.
- Terraform CLI and Azure CLI for local use.
- An Azure Storage account and private blob container for remote state. Bootstrap the backend separately before initializing the main configuration.
- A Linux VM SSH public key available in Azure if the VM configuration uses the Azure SSH public-key data source. Keep its matching private key out of the repository.
- An Azure DevOps project and Azure Resource Manager service connection using workload identity federation.
- Appropriate Azure RBAC assignments for both infrastructure deployment and Blob state access. These are separate permissions; grant each identity only the scope and roles it needs.

The example backend uses Azure CLI authentication for local runs. Configure the pipeline backend authentication to use the federated service connection, and grant that identity access to the state container and deployment scope.

## Run Terraform Locally

Authenticate to the intended Azure subscription, then run from the repository root:

```shell
az login
az account set --subscription <subscription-id>
terraform -chdir=terraform init
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform validate
terraform -chdir=terraform plan
```

`terraform plan` previews proposed changes but does not create resources. Review the plan before applying it. Applying the configuration can create billable resources.

## Configuration and Security

- Review the resource group, region, resource names, address ranges, Azure SSH public-key lookup, and backend settings before using the configuration in your environment.
- Keep the Terraform backend private. State may contain sensitive infrastructure details; protect it with identity-based access and appropriate storage controls.
- Never commit SSH private keys, credentials, state files, saved plans, or `.terraform/` contents. Use an approved secret store for any deployment secret that is genuinely required.
- Keep `.terraform.lock.hcl` under version control.
- Apply required Azure Policy and tagging standards to supported resource types. Some child resources, including subnets, do not support tags.

## Further Development

Possible extensions include a website build/test stage, artifact-based deployment, HTTP/HTTPS smoke tests, protected environment approvals for infrastructure changes, and a separately controlled cleanup workflow. Keep validation and planning available on pull requests, and avoid automatic production applies without review and policy controls.
