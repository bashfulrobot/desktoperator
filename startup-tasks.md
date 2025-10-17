# Desktoperator

## Summary

- Building a modern (in 2025) Ansible repo for configuring an Ubuntu based system.
- Packaging:
    - Favour in this order:
        - Deb
        - Flatpak
        - Snap
- Seperate apps from core system apps so that it is easy to understand dependencies (ssh keys, gpg, audio) on core desktop funcitonality vs apps being installed
- easy to do host specific configuration, but also share some of the config when it makes sense
- Want ansible best practices
- Be cautious of secrets leaking into the repo unless they are in my secret managment
- It needs to support multiple hosts
- Use a justfile for running tasks
- KISS when possible

## Consideratons

- How to manage secrets to protect leaking to remote git
    - ansible vault
    - git crypt
    - other?
    - Central location to store all sensitive values that can be pulled into other ansible code as needed
        - Almost like a settings file
- How to centralise repetative settings in a central location so that ansible code can pull from a central spot
- How to make bootstrapping a new system as easy as possible from a fresh install
- stretch goal, automate the Linux install itself
- Favour automation immensly over manual steps if possible and it makes sense
- Account for standardization
    - scripts
    - patterns
    - structure
    - etc
- use /commit command for git commits
- Application management strategy:
    - Should install and config happen in the same file/role for easy maintenance?
    - Or separate concerns (install vs config)?
- Import/include structure:
    - Keep imports organized and predictable
    - Avoid imports scattered throughout unless necessary
    - Clear hierarchy and flow
- Uninstall management:
    - How to handle removing packages/applications through Ansible?
    - State management for "absent" packages
    - Cleanup of config files when uninstalling
- Targeted execution:
    - Run only specific roles/tasks to avoid long run times
    - Tag strategy for selective execution
    - Just commands for common specific operations
- Config propagation strategy:
    - Push vs Pull model
    - Git-based config distribution
    - How to trigger updates across multiple hosts
    - Consider: cron-based pull, webhook triggers, or manual push

## Fisrt steps

- Propose a folder structure
- Propose secret management, considering easy bootstrap, avoiding "chicke and the egg" situations (if possible)
    - IE secrets use GPG, but GPG keys are not yet on the system
        - Or at least consider how to make it easy to get the dependencies for bootstrap
- Propose a central settings strategy
- Propose a bootstrap path
