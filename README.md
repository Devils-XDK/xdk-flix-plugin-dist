# XDKNet Plugin — Distribution

Public distribution repo for the **XDKNet** Jellyfin/Emby server plugin.

The plugin is built from its (private) source repository by CI and published
here automatically: each release's zips are attached as a **GitHub Release**,
and `manifest.json` is the plugin catalog that Jellyfin reads.

## Add to Jellyfin

1. Dashboard → **Administration** → **Plugins** → **Repositories**
2. Add a repository:
   - **Name:** `XDKNet`
   - **URL:** `https://raw.githubusercontent.com/Devils-XDK/xdk-flix-plugin-dist/main/manifest.json`
3. Go to **Catalog**, find **XDKNet**, and install it
4. Restart Jellyfin

Updates published here will then show up in Jellyfin's plugin catalog.

## Manual install

Download the latest `XDKNet.Server-x.x.x.x.zip` from
[Releases](https://github.com/Devils-XDK/xdk-flix-plugin-dist/releases) and
extract it into your Jellyfin `plugins/XDKNet/` folder, then restart Jellyfin.

## Emby

The Emby build (`XDKNet.Emby-x.x.x.x.zip`) is attached to the same releases as a
drop-in zip — extract its contents into your Emby `plugins/` folder.

---

Releases here are produced automatically; this repo holds distribution
artifacts only, not source.
