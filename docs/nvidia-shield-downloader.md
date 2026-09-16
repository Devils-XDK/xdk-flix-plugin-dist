# Installing XDKNet on the Nvidia Shield with Downloader

Sideloading the Android TV build onto an Nvidia Shield using **Downloader by
AFTVnews** (`com.esaba.downloader`).

## The short version

1. Install **Downloader** from the Play Store on the Shield.
2. Allow it to install apps - the Shield blocks this by default. See
   [Let Downloader install apps](#let-downloader-install-apps).
3. Open Downloader and enter the code, or this URL if no code is minted yet:

   ```
   github.com/Devils-XDK/xdk-flix-plugin-dist/releases/latest/download/XDKNet_AndroidTV.apk
   ```

4. Let it download, then choose **Install**.

## First-time setup

The permanent URL needs the fixed-name asset to exist. Releases published
before this was added only carry the versioned name, so backfill the current
one once:

**Actions → Publish Stable APK Alias → Run workflow** (leave the tag blank to
use the latest release).

The landing page at `/tv/` is separate and optional - the Downloader flow does
not need it. It requires Pages to be switched on once by hand, under
**Settings → Pages → Build and deployment → Source → GitHub Actions**, because
the Actions token is not allowed to create a Pages site itself.

It downloads the APK that release already carries and re-uploads the identical
bytes as `XDKNet_AndroidTV.apk`, leaving the versioned asset in place. After
that it runs automatically on every published release, so this is a one-time
step. Confirm before minting anything:

```bash
./scripts/check-downloader-url.sh     # expect RESULT: PASS
```

## Getting the numeric code

A "Downloader code" is not something this repo can generate. The codes are
short links on `aftv.news`, run by AFTVnews - the same developer as the app.
Typing digits into Downloader makes it fetch `https://aftv.news/<digits>`.

Mint one for XDKNet, once:

1. Go to **<https://go.aftvnews.com>**.
2. Paste the permanent APK URL:

   ```
   https://github.com/Devils-XDK/xdk-flix-plugin-dist/releases/latest/download/XDKNet_AndroidTV.apk
   ```

3. It returns a numeric code and a matching `aftv.news/<code>` link.
4. Verify the code resolves the way Downloader will resolve it:

   ```bash
   ./scripts/check-downloader-url.sh <code>
   ```

5. Record it below and publish it wherever the app is announced.

> **XDKNet Downloader code:** _not minted yet - see the steps above_

### Why that URL and not a release link

A code is minted once and then printed, shared and forgotten, so the URL behind
it has to outlive every future release. Two things break that:

- **A version in the filename.** Releases attach
  `XDKNet_AndroidTV_v2.3.5.apk`. A code pointing at it works today and 404s the
  day 2.3.6 ships. The `Publish Stable APK Alias` workflow attaches a second
  copy of the same bytes as `XDKNet_AndroidTV.apk`, which is what
  `/releases/latest/download/` resolves against forever.
- **Pointing at a page instead of the file.** Downloader names the saved file
  from the response. Aim a code at the landing page and it saves `index.html`,
  and Android never offers to install anything.

`./scripts/check-downloader-url.sh` checks both, plus the size, content type and
whether the bytes are really an APK. Run it before minting.

## Let Downloader install apps

The Shield refuses sideloads until Downloader is trusted, and the failure is
silent - the download finishes and nothing happens.

**Settings → Device Preferences → Security & restrictions → Unknown sources →
turn on _Downloader_.**

On Shield firmware where that path is missing, it is under **Settings → Device
Preferences → Security & restrictions → Install unknown apps**.

## Step by step

1. **Install Downloader.** Play Store on the Shield, search `Downloader by
   AFTVnews`. Allow storage access on first launch, or downloads fail.
2. **Trust it** as above.
3. **Enter the code or URL.** Select the URL field on the Home tab and type the
   code. Use the on-screen keyboard, or the Nvidia Shield phone app, which is
   far faster for a full URL.
4. **Download.** About 73 MB, with a progress bar.
5. **Install.** The Android installer opens when the download finishes. Choose
   **Install**, then **Done**.
6. **Delete the APK** when Downloader offers - it is no longer needed and the
   file is large.
7. XDKNet appears in the Shield's app row. Launch it and add your Jellyfin or
   Emby server.

## What gets installed

| | |
|---|---|
| Package | `org.xdknet.androidtv` |
| Size | ~73 MB |
| Architectures | arm64-v8a, armeabi-v7a, x86_64 (one universal APK; the Shield uses arm64) |
| Minimum Android | 7.0 in practice - see below |
| Signing | APK Signature Scheme v2 |

The manifest allows Android 6.0 (API 23), but the APK carries a v2 signature
with no v1 signature, and v2 verification only exists on Android 7.0+. So an
Android 6 device cannot install it regardless of the manifest. Every Shield
model ships well past 7.0, so this only matters for other hardware.

## Updating

Re-running the same code pulls whatever is current. Updates install over the
existing app and keep settings, as long as the new APK is signed with the same
key. A debug-signed build will not install over a release-signed one and fails
with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`; uninstall first in that case, which
does clear app data.

## When it does not work

| Symptom | Cause |
|---|---|
| Download finishes, nothing happens | Downloader is not trusted. See [above](#let-downloader-install-apps). |
| Downloader shows a web page instead of downloading | The URL resolves to HTML, not the APK. |
| Saved file is `index.html` | The code points at the landing page rather than the APK. |
| `404` partway through a code that used to work | The code points at a version-stamped asset that a newer release replaced. Re-point it at `XDKNet_AndroidTV.apk`. |
| `App not installed` | An XDKNet build signed with a different key is already installed. Uninstall it first. |
| `There was a problem parsing the package` | Truncated download, or Android below 7.0. Re-download. |

To diagnose a URL before blaming the device:

```bash
./scripts/check-downloader-url.sh                    # the permanent APK URL
./scripts/check-downloader-url.sh 123456             # a minted code
./scripts/check-downloader-url.sh https://host/x.apk # anything else
```

It walks the redirect chain the way Downloader does and reports the filename it
would save as, the content type, and the size - the three things that decide
whether a sideload works.

## Other ways in

- **Play Store** - XDKNet for Android TV is published as
  [`org.xdknet.androidtv`](https://play.google.com/store/apps/details?id=org.xdknet.androidtv).
  Prefer this unless you specifically want a build that is not on Play yet.
- **ADB**, with the Shield's network debugging on:

  ```bash
  adb connect <shield-ip>:5555
  adb install -r XDKNet_AndroidTV.apk
  ```

- **Landing page** at `/tv/`, for a browser or to share.
