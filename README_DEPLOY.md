# Automated Multi-Tier Application Deployment - ToDo App

This project implements a complete deployment pipeline for a Node.js ToDo application on AWS EC2 using Kubernetes.

## Components

### 1. Containerization (Docker)
- **Dockerfile**: Builds a production-ready image of the Node.js application.
- To build locally: `docker build -t todo-app .`

### 2. Infrastructure as Code (Terraform)
- Located in `terraform/`.
- Provisions a VPC, Subnet, Security Group, and an EC2 instance (`t2.medium`).
- Opens SSH and the Kubernetes NodePort (`30000`) so the app can be reached externally.
- **Setup**:
  1. `cd terraform`
  2. `terraform init`
  3. `terraform apply -var="key_name=<your-ec2-keypair-name>"`
  4. Note the `public_ip` and `application_url` outputs.

### 3. Configuration as Code (Ansible)
- Located in `ansible/`.
- Installs MicroK8s and prepares the EC2 node for Kubernetes.
- **Setup**:
  1. Update an inventory file with the EC2 Public IP.
  2. Run: `ansible-playbook -i inventory playbook.yml`

### 4. Cluster (Kubernetes Manifests)
- Located in `k8s/`.
- **Deployment**: Runs the app container with health probes.
- **Service**: Exposes the app via NodePort on port 30000.

### 5. CI/CD Pipeline
- **GitHub Actions**: `.github/workflows/deploy.yml` builds/pushes Docker image and updates the K8s manifest image tag.
- **ArgoCD**: `argocd-app.yaml` monitors this repository and manages CD synchronization.

## Deployment Steps
1. Push this repository to GitHub.
2. Set up GitHub Secrets: `DOCKER_USERNAME` and `DOCKER_PASSWORD`.
3. Provision infrastructure using Terraform.
4. Configure the node using Ansible.
5. Install ArgoCD on the cluster.
6. Apply the ArgoCD application manifest: `kubectl apply -f argocd-app.yaml`.
7. Open the Terraform `application_url` output in a browser.
