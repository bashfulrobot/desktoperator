# EFI Boot Order Management

This document covers how to discover and manage the EFI boot order on systems using systemd-boot (like Pop!_OS).

## Discovering Current Boot Order

### Check EFI Boot Entries and Order

```bash
sudo efibootmgr -v
```

This displays:
- `BootCurrent`: Currently booted entry
- `BootOrder`: Order of boot attempts (e.g., `0003,0000,0001,0006,0004`)
- Boot entries with their IDs, names, partitions, and EFI file paths

Example output:
```
BootCurrent: 0001
BootOrder: 0003,0000,0001,0006,0004
Boot0000* Windows Boot Manager
Boot0001* Pop!_OS 24.04 LTS
Boot0003* Hard Drive
Boot0006* UEFI OS
```

### Check systemd-boot Status

```bash
sudo bootctl status
```

This shows:
- Firmware information
- Current boot loader details
- Available boot loaders on ESP
- Boot loader entries in EFI variables
- Default boot loader entry

### List EFI Directory Structure

```bash
sudo ls -la /boot/efi/EFI/
```

Shows the actual EFI files and directories on the ESP partition.

## Setting Boot Order

### Reorder Boot Entries

To set a specific boot order, use the boot entry IDs discovered above:

```bash
sudo efibootmgr -o 0001,0000,0003,0006,0004
```

This sets the boot order to:
1. Boot0001 (Pop!_OS) - will boot first
2. Boot0000 (Windows)
3. Boot0003 (Hard Drive)
4. Boot0006 (UEFI OS)
5. Boot0004 (USB HDD)

The system will attempt to boot from each entry in order until one succeeds.

### Remove a Boot Entry (Optional)

To remove a problematic or unnecessary boot entry:

```bash
sudo efibootmgr -b 0003 -B
```

Where:
- `-b 0003` specifies the boot entry ID
- `-B` deletes the entry

**Warning:** Only remove entries you're certain are not needed. Removing the wrong entry could make your system unbootable.

## Common Scenarios

### Making Pop!_OS Boot by Default

If you get a "disk not found" error or Windows boots first:

```bash
# Check current order
sudo efibootmgr -v

# Set Pop!_OS (typically Boot0001) as first
sudo efibootmgr -o 0001,0000
```

### Making Windows Boot by Default

```bash
sudo efibootmgr -o 0000,0001
```

### Dual Boot with Manual Selection

Keep both entries in the boot order and configure your BIOS/UEFI to show the boot menu:
- Usually accessed via F11, F12, or ESC during boot
- Or configure a boot timeout in systemd-boot

## Troubleshooting

### "Disk not found" on Boot

This usually means the first boot entry is invalid or pointing to a disconnected drive. Check the boot order and move a valid entry (like Pop!_OS or Windows) to the first position.

### Changes Don't Persist

Some UEFI firmware resets boot order. You may need to:
1. Disable "Windows Boot Manager" prioritization in BIOS
2. Set "Linux Boot Manager" or "systemd-boot" as the preferred boot option in UEFI settings
3. Disable "Fast Boot" or "Fast Startup" in UEFI/Windows

### Boot Entry Missing After Reinstalling OS

Reinstall the bootloader:

For systemd-boot (Pop!_OS):
```bash
sudo bootctl install
```

This recreates the EFI boot entry.

## Related Files

- `/boot/efi/loader/loader.conf` - systemd-boot configuration
- `/boot/efi/loader/entries/` - Boot menu entries
- `/boot/efi/EFI/systemd/` - systemd-boot EFI binary
- `/boot/efi/EFI/BOOT/` - Fallback UEFI boot path

## Additional Resources

- `man efibootmgr` - Full efibootmgr documentation
- `man bootctl` - systemd-boot control documentation
- [systemd-boot documentation](https://www.freedesktop.org/software/systemd/man/systemd-boot.html)
