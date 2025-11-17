# zns - DNS Lookup Tool

Modern DNS lookup tool with smart defaults and colorized output.

## Overview

zns is a DNS lookup tool that provides a better user experience than traditional tools like dig. It features:

- Smart defaults for common queries
- Colorized output for better readability
- Fast and efficient lookups
- Support for multiple DNS record types

## Installation

This role installs zns from GitHub releases and configures fish shell integration.

## Configuration

### Variables

- `zns_version`: Version to install (default: "0.4.0")
- `app_states['zns']`: Installation state (present/absent)

### Fish Integration

The role creates a fish abbreviation `dig` that expands to `zns`, providing a familiar interface for users transitioning from dig.

## Usage

```fish
# After installation, use the dig abbreviation
dig example.com
dig example.com MX
dig example.com AAAA

# Or use zns directly
zns example.com
```

## Links

- [zns GitHub Repository](https://github.com/znscli/zns)
- [zns Releases](https://github.com/znscli/zns/releases)

## Tags

- zns
- cli
- network
- dns
