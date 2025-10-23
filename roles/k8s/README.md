# K8s Role

Kubernetes-related tools and services for managing Talos Linux clusters.

## Components

### Talosctl - Talos CLI

Installs [talosctl](https://www.talos.dev/), the command-line interface for managing Talos Linux clusters.

#### Features

- Direct binary installation from GitHub releases
- Version pinning support
- Idempotent installation (checks existing version)
- Automatic verification after installation

#### Configuration

```yaml
k8s_talosctl_enabled: true
k8s_talosctl_version: "v1.11.0"  # Pin to specific version
```

#### Usage

Once installed, use `talosctl` to manage your Talos cluster:

```bash
talosctl version                    # Check version
talosctl config endpoint <IP>       # Set cluster endpoint
talosctl dashboard                  # Open cluster dashboard
talosctl get nodes                  # List cluster nodes
```

See the [Talos documentation](https://www.talos.dev/v1.11/reference/cli/) for complete CLI reference.

### Kubectl - Kubernetes CLI

Installs [kubectl](https://kubernetes.io/docs/reference/kubectl/), the official Kubernetes command-line tool.

#### Features

- APT repository-based installation (official Kubernetes packages)
- Automatic updates via system package manager
- GPG key verification for package authenticity
- Version control via repository channels (v1.32, v1.31, etc.)

#### Configuration

```yaml
k8s_kubectl_enabled: true
k8s_kubectl_repo_version: "v1.32"  # Repository version channel
```

#### Usage

Once installed, use `kubectl` to interact with Kubernetes clusters:

```bash
kubectl version --client              # Check version
kubectl config view                   # View kubeconfig
kubectl get nodes                     # List cluster nodes
kubectl get pods -A                   # List all pods
kubectl apply -f manifest.yaml        # Apply configuration
```

See the [kubectl reference](https://kubernetes.io/docs/reference/kubectl/) for complete documentation.

### Booter - Talos PXE Boot Service

Installs and configures [siderolabs/booter](https://github.com/siderolabs/booter) for PXE booting Talos machines.

#### Features

- Docker-based deployment using docker-compose
- Convenient `booter` CLI wrapper for service management
- Configurable kernel parameters for Omni or standalone Talos

#### Usage

The role installs a `booter` command with the following options:

```bash
booter start      # Start the PXE boot service
booter stop       # Stop the service
booter restart    # Restart the service
booter status     # Check service status
booter logs       # View service logs
booter pull       # Pull latest image
```

#### Configuration

Configure booter by setting variables in your inventory or group_vars:

```yaml
k8s_booter_enabled: true
k8s_booter_version: "v0.2.0"
k8s_booter_dir: "{{ user.home }}/.config/booter"
k8s_booter_log_level: "info"

# For Omni users: Copy kernel parameters from Omni Overview page
k8s_booter_kernel_params: "talos.platform=metal console=ttyS0"
```

Alternatively, edit the docker-compose.yml directly at `~/.config/booter/docker-compose.yml`.

#### Requirements

- **Docker role must be run first** (this role depends on Docker being installed)
- Target machines must have UEFI PXE boot enabled
- Booter must run on the same subnet as target machines

#### Tags

Run just the k8s role:

```bash
ansible-playbook site.yml --tags k8s
```

## License

This role is part of the desktoperator project.
