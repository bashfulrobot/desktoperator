# RamaLama Role

Installs [RamaLama](https://github.com/containers/ramalama) - a tool for running AI LLMs via containers.

## Description

RamaLama is installed via `uv` (universal Python package installer). The tool allows you to run Large Language Models using Docker or Podman with GPU acceleration support.

**Host-Specific:** This role is configured to run only on the `qbert` host (AMD GPU).

## Requirements

- Docker or Podman must be installed
- Python 3.12+ (automatically handled by uv)
- GPU (optional, configured for AMD GPU on qbert)

## Configuration

Default variables in `defaults/main.yml`:

```yaml
# Python version requirement for uv installation
ramalama_python_version: "python3.12"

# Configuration settings (TOML format)
ramalama_config:
  engine: "docker"  # docker or podman
  runtime: "llama.cpp"  # llama.cpp, vllm, or mlx
  ngl: 999  # GPU layers (0=CPU only, 999=max GPU, -1=auto)
  threads: 8  # CPU threads for inference
  temp: 0.8  # Temperature (lower=deterministic, higher=creative)
  ctx_size: 8192  # Context window size
  store: "{{ user.home }}/.local/share/ramalama"  # Model storage directory
```

Configuration is deployed to `~/.config/ramalama/ramalama.conf` in TOML format.

## Usage

### Installation

Run the playbook with the ramalama tag:

```bash
ansible-playbook desktop.yml --tags ramalama
```

### Running RamaLama

After installation, ramalama will be available in your PATH:

```bash
# Run a model
ramalama run llama3

# List available models
ramalama list

# Pull a model
ramalama pull llama3
```

## Tags

- `dev` - General development tools tag
- `ramalama` - Specific to RamaLama installation

## State Management

Controlled via `app_states['ramalama']` in host-specific configuration (`inventory/host_vars/qbert.yml`):

- `present` - Install RamaLama (enabled on qbert)
- `absent` - Remove RamaLama

This role only runs on hosts where `app_states['ramalama']` is set to `present`.

## Implementation Details

- Installs `uv` (universal Python package installer) if not present
- Uses `uv tool install` to install ramalama with Python 3.12
- Installs to user's environment (via uv tool directory)
- Deploys TOML configuration to `~/.config/ramalama/ramalama.conf`
- Creates model storage directory at `~/.local/share/ramalama`
- Configured for GPU acceleration (AMD GPU on qbert)
- Checks if already installed to avoid reinstallation
- Assumes Docker/Podman is already installed

## References

- [RamaLama GitHub](https://github.com/containers/ramalama)
- [RamaLama Documentation](https://github.com/containers/ramalama/tree/main/docs)
