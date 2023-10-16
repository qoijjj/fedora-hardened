#!/bin/bash

if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    exit 1
fi

echo "Ensuring dnf plugins are installed"
dnf install -y dnf-plugins-core


echo "Installing the Arch hardened kernel from a copr..."
dnf copr enable -y samsepi0l/HardHatOS
dnf install -y kernel-hardened


echo "Ensuring openssl is installed"
dnf install -y openssl
MOK=./MOK.key
if test -f "$MOK"; then
    echo "$MOK exists, skipping MOK generation step."
else
echo "Generating new MOK..."
openssl req -newkey rsa:4096 -nodes -keyout MOK.key -new -x509 -sha256 -days 3650 -subj "/CN=my Machine Owner Key/" -out MOK.crt
openssl x509 -outform DER -in MOK.crt -out MOK.cer

echo "Importing MOK..."
mokutil --import MOK.cer
fi

echo "Signing vmlinuz..."
latest_vmlinuz=$(find /boot -name 'vmlinuz*hardened')
sbsign --key MOK.key --cert MOK.crt --output $latest_vmlinuz $latest_vmlinuz

echo "Signing bootloader..."
grub_efi_location="/boot/efi/EFI/fedora/grubx64.efi"
sbsign --key MOK.key --cert MOK.crt --output $grub_efi_location $grub_efi_location

echo "Signing shim..."
shim_efi_location="/boot/efi/EFI/BOOT/BOOTX64.EFI"
sbsign --key MOK.key --cert MOK.crt --output $shim_efi_location $shim_efi_location

echo "Setting numerous hardened sysctl values..."
cp ./config/hardening.conf /etc/sysctl.d/

echo "Disabling coredumps in limits.conf..."
cp ./config/limits.conf /etc/security/limits.conf

echo "Disabling all ports and services for firewalld..."
cp ./config/FedoraWorkstation.xml /etc/firewalld/zones/

echo "Blacklisting unused kernel modules..."
cp ./config/blacklist.conf /etc/modprobe.d/

echo "Setting more restrictive file permissions..."
chmod 600 /etc/at.deny
chmod 600 /etc/cron.deny
chmod 600 /etc/crontab
chmod 700 /etc/cron.d
chmod 700 /etc/cron.daily/
chmod 700 /etc/cron.daily
chmod 700 /etc/cron.hourly
chmod 700 /etc/cron.weekly
chmod 700 /etc/cron.monthly

echo "Installing dnf-automatic and chkrootkit..."
dnf install -y dnf-automatic chkrootkit

echo "Setting hardening kernel parameters..."
grubby --update-kernel=ALL --args="lsm=landlock,lockdown,yama,integrity,selinux,bpf init_on_alloc=1 init_on_free=1 slab_nomerge page_alloc.shuffle=1 randomize_kstack_offset=on vsyscall=none debugfs=off lockdown=confidentiality random.trust_cpu=off random.trust_bootloader=off nvme_core.default_ps_max_latency_us=0 mitigations=auto,nosmt"

echo "Installing Brave Browser and its RPM repo..."
dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
dnf install -y brave-browser

echo "Building hardened_malloc..."
dnf install -y rpm-build rpmdevtools rpmlint gcc make g++
rm -r fedora-extras
git clone https://github.com/rusty-snake/fedora-extras.git
cd fedora-extras
./rpmbuild.sh hardened_malloc

echo "Installing hardened_malloc"
dnf install -y hardened_malloc*.rpm
cd ..
cp -f ./config/ld.so.preload /etc/

echo "Complete. Reboot your system for changes to take effect."
