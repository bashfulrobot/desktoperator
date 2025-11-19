# Network Configuration Role

This role configures network bridges on Ubuntu using netplan, primarily for use with libvirt/KVM virtualization.

## Features

- Creates network bridges using netplan
- Supports DHCP or static IP configuration
- Automatic backup of existing netplan configurations
- Proper error handling and rollback support

## Variables

### Required Variables

None - all variables have sensible defaults.

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `network_create_bridge` | `false` | Enable bridge creation |
| `network_bridge_name` | `br0` | Name of the bridge device |
| `network_bridge_interface` | Auto-detected | Physical interface to bridge |
| `network_bridge_type` | `dhcp` | IP configuration type (`dhcp` or `static`) |
| `network_bridge_static_ip` | `""` | Static IP address (if type is `static`) |
| `network_bridge_static_gateway` | `""` | Gateway IP (if type is `static`) |
| `network_bridge_static_nameservers` | `[]` | DNS servers (if type is `static`) |
| `network_netplan_renderer` | `networkd` | Netplan renderer (`NetworkManager` or `networkd`) |

## Usage

### Basic Bridge with DHCP

Add to your host_vars:

```yaml
network_create_bridge: true
network_bridge_name: "br0"
network_bridge_type: "dhcp"
```

### Bridge with Static IP

Add to your host_vars:

```yaml
network_create_bridge: true
network_bridge_name: "br0"
network_bridge_type: "static"
network_bridge_static_ip: "192.168.1.100/24"
network_bridge_static_gateway: "192.168.1.1"
network_bridge_static_nameservers:
  - "8.8.8.8"
  - "1.1.1.1"
```

### Specify Interface

By default, the role uses `ansible_default_ipv4.interface`. To override:

```yaml
network_create_bridge: true
network_bridge_name: "br0"
network_bridge_interface: "enp3s0"
```

## Integration with libvirt

After creating a bridge, configure libvirt to use it:

```yaml
libvirt_bridged_networks:
  - name: "host-bridge"
    bridge: "br0"
    autostart: true
```

VMs attached to this network will get IP addresses from your existing DHCP server and appear as devices on your LAN.

## Important Notes

- **Network Disruption**: Applying the bridge configuration will temporarily disconnect the network. Ensure you have local access or IPMI/iDRAC available.
- **Backup**: Existing netplan files are automatically backed up before modification.
- **Recovery**: If the configuration fails, you can restore from the backup files in `/etc/netplan/*.backup-*`.

## Example: Complete Setup for qbert

In `inventory/host_vars/qbert.yml`:

```yaml
# Network bridge configuration
network_create_bridge: true
network_bridge_name: "br0"
network_bridge_type: "dhcp"

# Libvirt bridged network (uses host bridge for direct LAN access)
libvirt_bridged_networks:
  - name: "host-bridge"
    bridge: "br0"
    autostart: true
```

## Tags

- `network`: All network tasks
- `bridge`: Bridge-specific tasks
- `netplan`: Netplan configuration tasks

## Dependencies

- Ubuntu with netplan
- bridge-utils package (installed by libvirt role)

## Files

- `tasks/main.yml`: Main task file
- `templates/bridge-netplan.yaml.j2`: Netplan configuration template
- `defaults/main.yml`: Default variables
- `handlers/main.yml`: Handler for applying netplan changes
