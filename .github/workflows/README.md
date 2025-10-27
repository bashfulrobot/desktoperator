# Automated Zen Browser PPA Builds

This GitHub Actions workflow automatically checks for new Zen Browser releases and uploads packages to your PPA nightly.

## Setup Instructions

### 1. Export Your GPG Key

Your GPG key must be registered with Launchpad and stored in GitHub Secrets.

```bash
# List your GPG keys to find the correct one
gpg --list-secret-keys --keyid-format LONG

# Export the private key (use the key ID from above)
gpg --armor --export-secret-keys YOUR_KEY_ID > private-key.asc

# The exported key is in private-key.asc
# DO NOT commit this file - it will be added to GitHub Secrets
```

### 2. Add GitHub Secrets

Go to your repository on GitHub:
1. Navigate to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add these secrets:

**Secret: `GPG_PRIVATE_KEY`**
- Copy the entire contents of `private-key.asc`
- Paste into the secret value field

**Secret: `GPG_PASSPHRASE`**
- Enter your GPG key passphrase
- If your key has no passphrase, leave this empty

### 3. Verify GPG Key in Launchpad

Ensure your GPG key is registered with Launchpad:
1. Go to https://launchpad.net/~bashfulrobot/+editpgpkeys
2. Verify your key fingerprint is listed
3. If not, add it and confirm via email

### 4. Test the Workflow

**Manual trigger:**
1. Go to **Actions** tab in GitHub
2. Select **Build Zen Browser PPA** workflow
3. Click **Run workflow**
4. Optionally check "Force rebuild" to test with `--force` flag

**View logs:**
- Click on the running workflow to see live logs
- Build artifacts (logs) are uploaded on failure

## How It Works

### Schedule
- Runs **nightly at 2 AM UTC**
- Can be triggered **manually** anytime from Actions tab

### Build Logic
1. Checks GitHub for latest Zen Browser release
2. Queries your PPA for current version
3. **Skips build** if PPA already has latest version
4. **Builds and uploads** if new version available
5. **Force mode** rebuilds even if version exists (increments Debian revision)

### What Gets Built
- Source packages for Ubuntu Noble (24.04) and Jammy (22.04)
- Uploaded to `ppa:bashfulrobot/zen-browser`
- Launchpad builds the binary .deb packages

### Version Management
- Follows Ubuntu PPA versioning: `upstream-debian~distroN`
- Auto-increments Debian revision for packaging fixes
- Resets to revision 1 for new upstream versions

## Workflow Outputs

### Success
- Packages uploaded to Launchpad
- Monitor builds at: https://launchpad.net/~bashfulrobot/+archive/ubuntu/zen-browser/+builds

### Failure
- Build logs uploaded as artifacts
- Check workflow run for details
- Review build-*.log files

## Troubleshooting

### "gpg: decryption failed: No secret key"
- Your GPG key isn't properly imported
- Verify `GPG_PRIVATE_KEY` secret is set correctly
- Ensure you exported with `--armor --export-secret-keys`

### "Upload has already been done"
- Launchpad rejects duplicate source versions
- This is expected if no new version available
- Use force mode to rebuild with incremented revision

### "No package matching 'zen-browser' is available"
- Build failed on Launchpad
- Check build logs: https://launchpad.net/~bashfulrobot/+archive/ubuntu/zen-browser/+builds?build_state=failed
- Common issues: packaging errors, missing dependencies

## Security Notes

- GPG keys are stored encrypted in GitHub Secrets
- Never commit GPG keys to the repository
- Delete `private-key.asc` after adding to GitHub Secrets
- Workflow only runs on `main` branch (protected)
- Only repository admins can modify workflow files

## Customization

### Change Schedule
Edit `.github/workflows/build-zen-ppa.yml`:
```yaml
schedule:
  - cron: '0 2 * * *'  # 2 AM UTC daily
  # Examples:
  # - cron: '0 */6 * * *'  # Every 6 hours
  # - cron: '0 0 * * 0'    # Weekly on Sunday
```

### Add Email Notifications
Add to the end of the workflow:
```yaml
      - name: Send notification
        if: failure()
        run: |
          # Your notification script here
```

## Alternative: Launchpad Recipes

If you prefer to build entirely on Launchpad infrastructure, you can use **Launchpad Recipes**. However, this is more complex for repackaging pre-compiled binaries.

See: https://help.launchpad.net/Packaging/SourceBuilds/Recipes
