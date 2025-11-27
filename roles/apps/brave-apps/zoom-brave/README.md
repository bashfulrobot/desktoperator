# Zoom Brave Web App with URL Handler

This role sets up Zoom as a Brave web app with intelligent URL handling and transformation.

## Architecture

```
Zoom URL clicked
  ↓
xdg-open (system)
  ↓
zoom-url.desktop (URL handler)
  ↓
zoom-url-handler.sh (transforms URL)
  ↓
brave-Zoom (launcher)
  ↓
Brave browser --app=URL (logged-in instance)
```

## Components

### 1. URL Handler (`zoom-url-handler.sh`)
- **Location:** `/usr/local/bin/zoom-url-handler`
- **Purpose:** Intercepts and transforms Zoom URLs
- **Handles:**
  - Standard join URLs: `/j/` → `/wc/join/`
  - Native protocol: `zoommtg://` → `https://...wc/join/`
  - Already transformed URLs (pass through)
  - Non-Zoom URLs (fallback to default browser)
- **Logging:** `~/.local/share/zoom-url-handler.log`

### 2. URL Handler Desktop Entry (`zoom-url.desktop`)
- **Location:** `/usr/share/applications/zoom-url.desktop`
- **Purpose:** Registers handler for Zoom URLs
- **Protocols:** `http://`, `https://`, `zoommtg://`
- **Hidden:** Does not appear in application menu

### 3. Zoom Launcher (`brave-Zoom-launcher.sh`)
- **Location:** `/usr/local/bin/brave-Zoom`
- **Purpose:** Launches Zoom in Brave app mode
- **Usage:**
  - No args: Opens default Zoom home
  - With URL: Opens specific URL in Zoom app
- **Maintains:** Logged-in session across invocations

### 4. Zoom Desktop Entry (`brave-Zoom.desktop`)
- **Location:** `/usr/share/applications/brave-Zoom.desktop`
- **Purpose:** User-facing app launcher
- **Visible:** Appears in application menu

## URL Transformations

| Input URL | Transformed URL |
|-----------|----------------|
| `https://*/j/123?pwd=x` | `https://*/wc/join/123?pwd=x` |
| `https://*/wc/join/123` | `https://*/wc/join/123` (unchanged) |
| `zoommtg://.../confno=123&pwd=x` | `https://*/wc/join/123?pwd=x` |
| `https://zoom.us/profile` | `https://zoom.us/profile` (unchanged) |

## Testing

Run the test script to validate URL handling:

```bash
bash roles/apps/brave-apps/zoom-brave/files/test-zoom-url-handler.sh
```

Or manually test transformations:

```bash
/usr/local/bin/zoom-url-handler "https://konghq.zoom.us/j/123456?pwd=test"
```

## Logs

View URL handler logs:

```bash
cat ~/.local/share/zoom-url-handler.log
```

## Manual Registration

If you need to manually register the URL handler:

```bash
# For zoommtg:// protocol
xdg-mime default zoom-url.desktop x-scheme-handler/zoommtg

# For general URL routing (requires central router)
# See: roles/apps/url-router/
```

## Troubleshooting

### URLs not being transformed
Check the log file for errors:
```bash
tail -f ~/.local/share/zoom-url-handler.log
```

### Wrong browser opens
Verify the URL handler is registered:
```bash
xdg-mime query default x-scheme-handler/zoommtg
# Should return: zoom-url.desktop
```

### Zoom app not launching
Test the launcher directly:
```bash
/usr/local/bin/brave-Zoom "https://zoom.us/wc/home"
```

## Integration with Central URL Router

This role is designed to work standalone or with a central URL router:

**Standalone:** Only handles `zoommtg://` protocol
**With Router:** Handles all `zoom.us` HTTPS URLs via central routing

See `roles/apps/url-router/` for central routing configuration.
