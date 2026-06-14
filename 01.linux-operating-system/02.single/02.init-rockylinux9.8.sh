#!/bin/bash

# 色卡
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

print_colored() {
  local color="$1"
  local message="$2"
  echo -e "${color}${message}${NC}"
}

ARCH=x86_64

function check_root {
  if [[ $EUID -ne 0 ]]; then
    print_colored "$RED" "[Error] This script must be run as root"
    exit 1
  fi
  print_colored "$GREEN" "[Success] Root user checked"
}

function check_selinux() {
  local selinux_status
  selinux_status=$(getenforce)
  if [[ "$selinux_status" == "Enforcing" ]]; then
    setenforce 0
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    print_colored "$GREEN" "[Success] SELinux disabled"
  else
    print_colored "$GREEN" "[Success] SELinux is already disabled"
  fi
}

function check_firewall() {
  local firewall_status
  firewall_status=$(systemctl is-active firewalld)
  if [[ "$firewall_status" == "active" ]]; then
    systemctl disable firewalld --now
    print_colored "$GREEN" "[Success] Firewall disabled"
  else
    print_colored "$GREEN" "[Success] Firewall is already disabled"
  fi
}

function update_software_sources() {
  local bak_dir
  bak_dir="/etc/yum.repos.d/bak_$(date +%Y%m%d_%H%M%S)"
  mkdir "$bak_dir"
  cp -a /etc/yum.repos.d/*.repo "$bak_dir"
  sed -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^#baseurl=http://dl.rockylinux.org/$contentdir|baseurl=https://mirrors.aliyun.com/rockylinux|g' \
    -i.bak \
    /etc/yum.repos.d/rocky*.repo
  yum clean all
  yum makecache
  print_colored "$GREEN" "[Success] Software sources updated"
}

function install_necessary_tools() {
  yum install -y vim wget net-tools lsof iotop chrony unzip tree gcc make perl gcc-c++ cmake tar
  if [[ $? -ne 0 ]]; then
    print_colored "$RED" "[Error] Failed to install necessary tools"
    exit 1
  fi
  print_colored "$GREEN" "[Success] Necessary packages installed"
}

function set_timezone() {
  timedatectl set-timezone Asia/Shanghai
  if [[ $? -ne 0 ]]; then
    print_colored "$RED" "[Error] Failed to set timezone"
    exit 1
  fi
  print_colored "$GREEN" "[Success] Timezone set to Asia/Shanghai"
}

function sync_time() {
  systemctl enable chronyd --now
  if [[ $? -ne 0 ]]; then
    print_colored "$RED" "[Error] Failed to start chrony service and enable on boot"
    exit 1
  fi

  cat >/etc/chrony.conf <<EOF
# Use public servers from the pool.ntp.org project.
# Please consider joining the pool (http://www.pool.ntp.org/join.html).
server ntp1.aliyun.com iburst
server ntp2.aliyun.com iburst
server ntp3.aliyun.com iburst
server ntp4.aliyun.com iburst

# Record the rate at which the system clock gains/losses time.
driftfile /var/lib/chrony/drift

# Allow the system clock to be stepped in the first three updates
# if its offset is larger than 1 second.
makestep 1.0 3

# Enable kernel synchronization of the real-time clock (RTC).
rtcsync

# Enable hardware timestamping on all interfaces that support it.
#hwtimestamp *

# Increase the minimum number of selectable sources required to adjust
# the system clock.
#minsources 2

# Allow NTP client access from local network.
#allow 192.168.0.0/16

# Serve time even if not synchronized to a time source.
#local stratum 10

# Specify file containing keys for NTP authentication.
#keyfile /etc/chrony.keys

# Specify directory for log files.
logdir /var/log/chrony

# Select which information is logged.
#log measurements statistics tracking
EOF

  timedatectl
  print_colored "$GREEN" "[Success] Time synchronized with chrony service In Public NTP Servers"
  print_colored "$YELLOW" "[Warning] Please manually edit the chrony service In Private NTP Servers, restart the chrony service and manually synchronize the clock time using 'hwclock --systohc'"

  hwclock -w
  if [[ $? -ne 0 ]]; then
    print_colored "$RED" "[Error] Failed to sync hardware clock with system time"
    exit 1
  fi
}

function main() {
  check_root
  check_selinux
  check_firewall
  update_software_sources
  install_necessary_tools
  set_timezone
  sync_time
}

main
