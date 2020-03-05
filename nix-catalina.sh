#!/usr/bin/env bash

set -e -o pipefail

if [ "${1:-}" = "-h" ]; then
  echo "This prepares a system for macOS Catalina. It takes no options."
  exit 1
fi

if [ $(id -u) -ne 0 ]; then
  echo "please run ${0} with sudo."
  exit 1
fi

# If a nix volume somewhere, don't create a new one.
if ! [ -d /Volumes/Nix ] && ! diskutil info Nix >/dev/null; then
  cat <<EOF
Did not detect a dedicated nix volume. Creating one
and replicating /nix to it (if it exists).
EOF

  declare disk=$(diskutil info / | grep "Part of Whole:" | cut -f2 -d: | tr -d '[:space:]')
  diskutil apfs addVolume ${disk} APFSX Nix
  diskutil enableOwnership /Volumes/Nix
  echo "Saving the current /nix directory to it's new location"
  rsync -a --progress /nix/ /Volumes/Nix/ || true
  chown -R "${SUDO_USER}" /Volumes/Nix || true
fi

if ! grep "LABEL=Nix /nix" -q /etc/fstab 2>&1 >/dev/null; then
  echo "Setting up fstab to mount /nix on catalina boot"
  echo "LABEL=Nix /nix apfs rw" >>/etc/fstab
fi

if ! grep -q nix /etc/synthetic.conf 2>&1 >/dev/null; then
  echo "Adding nix to synthetic.conf"
  echo nix >>/etc/synthetic.conf
fi

cat <<EOF
At this point, you can begin the Catalina install process.

If you are already running Catalina, you must reboot for the process to complete.

After complete catalina install, re-run:
xcode-select --install
curl https://nixos.org/nix/install | sh

EOF
