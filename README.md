# fedora-hardened

## Notice

- This script only supports Fedora 38 until further notice.
- This script is in *alpha*, **use at your own risk**.
- Not compatible with nvidia because kernel-devel packages aren't available from the copr.

## What

This is a script that hardens the default fedora installation significantly using the following modifications:

- Installing the [Arch hardened kernel](https://github.com/anthraxx/linux-hardened) from a copr (Thanks to [@d4rklynk](https://github.com/d4rklynk) for [maintaining it](https://github.com/d4rklynk/kernel-hardened))
- Generates, installs, and signs the kernel and bootloader with a new machine owner key so secureboot will still function
- Setting numerous hardened sysctl values (Inspired by but not the same as Kicksecure's)
- Disabling coredumps in limits.conf
- Disabling all ports and services for firewalld
- Blacklisting numerous unused kernel modules to reduce attack surface
- Setting more restrictive file permissions (Based on recommendations from [lynis](https://cisofy.com/lynis/))
- Installing dnf-automatic and chkrootkit
- Sets numerous hardening kernel parameters (Inspired by [Madaidan's Hardening Guide](https://madaidans-insecurities.github.io/guides/linux-hardening.html))
- Installs and enables [hardened_malloc](https://github.com/GrapheneOS/hardened_malloc) globally
- Installing Brave Browser and its rpm repo (Unfortunately, the Fedora Chromium rpm is consistently behind security patches, so Brave provides an up-to-date [Chromium-based browser](https://madaidans-insecurities.github.io/firefox-chromium.html). Brave also has content blocking built-in, avoiding the need for [MV2 extensions](https://forums.whonix.org/t/chromium-browser-for-kicksecure-discussions-not-whonix/10388))

## Why

Fedora is one of the few distributions that ships with selinux and associated tooling built-in and enabled by default. This makes it advantageous as a starting point for building a hardened system. However, out of the box it's lacking hardening in numerous other areas. This project's goal is to improve on that significantly by providing an easy to use and idempotent post-install script.

## How

```
# ./harden.sh
```

