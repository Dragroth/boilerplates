#version=RHEL9
# This file was generated using the Kickstart Generator page, see below:
# https://access.redhat.com/labs/kickstartconfig/

# Use network installation
url --url="ftp://10.11.1.20/pub/pxe/Rocky9/BaseOS"
repo --name="AppStream" --baseurl="ftp://10.11.1.20/pub/pxe/Rocky9/AppStream"
# Disable Initial Setup on first boot
firstboot --disable

# Use text mode install
text
# Keyboard layouts
keyboard --vckeymap=gb --xlayouts='gb'
# System language
lang en_GB.UTF-8
# SELinux configuration
selinux --enforcing
# Firewall configuration
firewall --enabled --ssh
# Do not configure the X Window System
skipx

# Network information
network --bootproto=dhcp --device=eth0 --nameserver=10.11.1.2,10.11.1.3 --noipv6 --activate
network --hostname=rocky9.localdomain

# System authorisation information
auth --useshadow --passalgo=sha512
# Root password
rootpw packer
# Root SSH public key
sshkey --username=root "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCzcZWKJVeDTioSe5x1M7WdNGgX4HQsZQeP92zK2LlP7vymnzts/IZz4I5r6Z0WwSMh9VxN9IABxsotdohiC9kroEdqUG9/OmljQhHNXnMOlAhnofJAnnEb7Tr1v1xGJllpQ135PNL+ECTIslQMBD68a2WZGLvJBPg/WSEsaD6oWwVnrldXIolvDaAKx3TnipwoEp/jcZ1KXTA6LuqdpG1XDI35pT8QF9bO79nv05nf9ypynJxMZZ66HcwiKnoNbyY/Xa2b1Yyv5WA+2kY821bKMaYiKRuwABZI/1M5kLLki6RZ9rvUG8FfiJVhhAJXOIguT1reBdQsBfxqLirotf2t8kOzGbKwwXIPqePtTlCFe0GKT5H6qe1x1kXBPF4+m2r2JPllhwcnNtPl5MVn9X/HQSDRgYtTPlXREuyLLWD1n4vpcka6YMrCulE9KJmnN1J++rRGLgeU47/lgFwKOfF0yugMyfTTrbYUffzBDBsV8mSelra/sm4ZwrkjOzNiSStUAHZ6WL4t2vNs94B61eVKHMFKFSbFKeQ79qEisJkQp4pOUJDmNohMZKquNThrwX5qhVsNFJ28mZfYvJrxn+ha2M3by9+WealubGy14FFGz5Ir7UWmL8IsB5Bq+USwiVxOy+TBecMUNyuy5H0ttX7gbkvo3mRF9h4apfcFlxtZlQ== tom@hl.test"
# System timezone
timezone Europe/London --utc

ignoredisk --only-use=vda
# System bootloader configuration
bootloader --location=mbr --timeout=1 --boot-drive=vda
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all --initlabel
# Reboot after installation
reboot

# Disk partitioning information
#autopart --type=lvm
part /boot --fstype="xfs" --ondisk=vda --size=1024 --label=boot --asprimary --fsoptions="rw,nodev,noexec,nosuid"
part pv.01 --fstype="lvmpv" --ondisk=vda --size=31743
volgroup vg_os pv.01
logvol /tmp  --fstype="xfs" --size=1024 --label="lv_tmp" --name=lv_tmp --vgname=vg_os --fsoptions="rw,nodev,noexec,nosuid"
logvol /  --fstype="xfs" --size=30716 --label="lv_root" --name=lv_root --vgname=vg_os

%packages
# dnf group info minimal-environment
@^minimal-environment
sudo
qemu-guest-agent
openssh-server
# Alsa not needed in a VM
-alsa*
# Microcode updates cannot work in a VM
-microcode_ctl
# Firmware packages are not needed in a VM
-iwl*firmware
# Don't build rescue initramfs
-dracut-config-rescue
-plymouth
%end

%addon com_redhat_kdump --disable --reserve-mb='auto'
%end

%post 
sed -i 's/^.*requiretty/#Defaults requiretty/' /etc/sudoers
sed -i 's/rhgb //' /etc/default/grub
# SSHD PermitRootLogin and enable the service
sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
/usr/bin/systemctl enable sshd
# Update all packages
/usr/bin/yum -y update
%end