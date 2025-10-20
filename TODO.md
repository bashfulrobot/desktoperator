# TODO

Outstanding tasks and features to implement.

## Configuration Tasks

### GPG Key Management

**Status:** Disabled (not configured)
**Priority:** Medium
**Location:** `roles/system/tasks/gpg.yml`

The GPG import task is currently commented out in `roles/system/tasks/main.yml` because it requires:

1. **Define `gpg_private_keys` in vault:**
   - Add GPG private key(s) to `inventory/group_vars/all/vault.yml`
   - Format: Dictionary with key names and base64-encoded private keys

2. **Test the import process:**
   - Verify keys import correctly
   - Ensure proper permissions and ownership

3. **Document usage:**
   - Add instructions to docs/GPG_SETUP.md
   - Include key generation and export instructions

4. **Re-enable the task:**
   - Uncomment lines 37-39 in `roles/system/tasks/main.yml`
   - Test with `just tag gpg`

**Related Files:**
- `roles/system/tasks/gpg.yml` - GPG import task
- `roles/system/tasks/main.yml` - Task disabled here (lines 36-39)
- `inventory/group_vars/all/vault.yml` - Where keys should be stored

---

## Future Enhancements

### Browser Theming

**Gmail System Theme Mode Extension**
- Chrome/Vivaldi extension for Gmail to follow system dark/light mode
- Repository: https://github.com/bernardolob/Gmail-System-Theme-mode
- Consider adding to Vivaldi role if needed

---

(Add additional TODOs here as needed)
