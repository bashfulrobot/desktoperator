# GitHub Brave Web App

This is a proof of concept Brave-based web app that opens `https://github.com`
with a dedicated launcher and icon set derived from the existing Pake assets.

Use `ansible-playbook site.yml --tags github-brave` to install. The launcher
shares your main Brave profile (logins, extensions, bookmarks), runs in Wayland
mode, and stays associated with `brave-github` so the icon works in Alt+Tab.
