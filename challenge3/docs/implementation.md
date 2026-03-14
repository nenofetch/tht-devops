# Implementation

## 1) The single-VM on Azure VM Using OpenTofu IaC

### Goal

Simple, cheap, fast: one VM that serves a static site. Easy to manage and great for demos or small projects.

### What I provisioned

- **Azure VM**: A single Linux VM (Ubuntu 22.04 LTS) with a public IP at Central India (more cheap for the pricing instead another region).
- **Nginx**: To serve a simple "Hello, OpenTofu!" webpage.
- **Prometheus Node Exporter**: For basic metrics (CPU, memory).
- **Firewalld**: To restrict access to only necessary ports (80 for HTTP, 9100 for node_exporter).
- `cloud-init.sh` installs nginx + node_exporter and opens firewall

### How-to notes

1. Keep Azure credentials out of repo. Use GitHub Secrets or Azure Key Vault.
2. In `challenge3` folder use `tofu init`, `tofu plan`, `tofu apply`.
3. After apply, `tofu output public_ip` and visit `http://<public_ip>`.
4. SSH username depends on image: `opc` for Oracle Linux, `ubuntu` for Ubuntu.(<[References](https://docs.oracle.com/en-us/iaas/Content/Compute/tutorials/first-linux-instance/overview.htm)>)

## 2) CI/CD (how I wired it)

- **challenge3**: OpenTofu plan on PRs, apply on main (see `.github/workflows/tofu.yml`).
- Store Azure config in `secrets.AZURE_`, and per-variable secrets (`AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_TENANT_ID`) if you prefer TF_VAR style and RBAC Authentication.

Why this CI choice?

- Plan on PR reduces chance of accidental infra changes.
- Apply only on main avoids surprises.
- Separate app & infra pipelines reduces risk.

## 3) Network

- For VM: use an simple network such as Virtual Network (VNet) with a single subnet, and assign a public IP to the VM for external access.
- For security: use Network Security Group (NSG) to restrict inbound traffic to only necessary ports (80 for HTTP, 9100 for node_exporter) and block all other traffic.

## 4) Observability

- Node_Exporter Prometheus: for metric collection such as cpu/memory usage, on this machine it was installed Prometheus Node_Exporter as on the cloud-init.sh file, and for the port is using 9100

## 5) Security

- Firewalld: for the simple security on this case it implement on firewalld on the machine with specific port open/expose to the public and also on security list on VCN
