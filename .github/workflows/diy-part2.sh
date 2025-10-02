#!/bin/bash
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# File name: diy-part2.sh
# Description: ImmortalWrt DIY script part 2 (After Update feeds)
#

# Modify default IP
sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate

# Modify hostname
sed -i 's/ImmortalWrt/ImmortalWrt-Router/g' package/base-files/files/bin/config_generate

# Modify the version number
sed -i "s/OpenWrt /ImmortalWrt Build $(TZ=UTC-8 date "+%Y.%m.%d") @ ImmortalWrt /g" package/lean/default-settings/files/zzz-default-settings

# Modify default theme
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Set default language to Chinese
sed -i 's/luci.main.lang=auto/luci.main.lang=zh_cn/g' package/lean/default-settings/files/zzz-default-settings

# Add custom settings
cat >> package/lean/default-settings/files/zzz-default-settings <<EOF

# Set timezone
uci set system.@system[0].timezone='CST-8'
uci set system.@system[0].zonename='Asia/Shanghai'
uci commit system

# Set NTP servers
uci set system.ntp.enabled='1'
uci set system.ntp.enable_server='0'
uci del system.ntp.server
uci add_list system.ntp.server='ntp1.aliyun.com'
uci add_list system.ntp.server='ntp2.aliyun.com'
uci add_list system.ntp.server='time1.cloud.tencent.com'
uci add_list system.ntp.server='time2.cloud.tencent.com'
uci commit system

# Enable SSH
uci set dropbear.@dropbear[0].PasswordAuth='on'
uci set dropbear.@dropbear[0].RootPasswordAuth='on'
uci set dropbear.@dropbear[0].Port='22'
uci commit dropbear

# Set SFTP
uci set vsftpd.@vsftpd[0].enabled='1'
uci set vsftpd.@vsftpd[0].anonymous='0'
uci set vsftpd.@vsftpd[0].local_enable='1'
uci set vsftpd.@vsftpd[0].write_enable='1'
uci set vsftpd.@vsftpd[0].local_umask='022'
uci commit vsftpd

# Set Samba
uci set samba4.@samba[0].name='ImmortalWrt'
uci set samba4.@samba[0].workgroup='WORKGROUP'
uci set samba4.@samba[0].description='ImmortalWrt Router'
uci set samba4.@samba[0].charset='UTF-8'
uci set samba4.@samba[0].enable_extra_tuning='1'
uci commit samba4

# Expand overlay space to 2GB
sed -i 's/256/2048/g' target/linux/x86/image/Makefile

# Enable irqbalance
uci set irqbalance.irqbalance.enabled='1'
uci commit irqbalance

# Set default password
sed -i 's/root::0:0:99999:7:::/root:\$1\$V4UetPzk\$CYXluq4wUazHjmCDBCqXF.:0:0:99999:7:::/g' /etc/shadow

# Auto mount USB storage
block detect > /etc/config/fstab
uci set fstab.@global[0].anon_mount='1'
uci commit fstab

EOF

# Fix HomeProxy build
mkdir -p feeds/homeproxy/luci-app-homeproxy/po/zh_Hans
[ ! -f feeds/homeproxy/luci-app-homeproxy/po/zh_Hans/homeproxy.po ] && \
    cp feeds/homeproxy/luci-app-homeproxy/po/zh-cn/homeproxy.po feeds/homeproxy/luci-app-homeproxy/po/zh_Hans/homeproxy.po

# Fix permissions
chmod -R 755 package/luci-app-openclash/root/usr/share/openclash/
chmod -R 755 package/luci-app-diskman/root/usr/share/diskman/

# Download clash core for OpenClash
mkdir -p package/base-files/files/etc/openclash/core
CLASH_DEV_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/dev/clash-linux-amd64.tar.gz"
CLASH_TUN_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/premium/clash-linux-amd64-2023.08.17-13-gdcc8d87.gz"
CLASH_META_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-amd64.tar.gz"

wget -qO- $CLASH_DEV_URL | tar xOvz > package/base-files/files/etc/openclash/core/clash 2>/dev/null
wget -qO- $CLASH_TUN_URL | gunzip -c > package/base-files/files/etc/openclash/core/clash_tun 2>/dev/null
wget -qO- $CLASH_META_URL | tar xOvz > package/base-files/files/etc/openclash/core/clash_meta 2>/dev/null

chmod +x package/base-files/files/etc/openclash/core/clash* 2>/dev/null

# Custom banner
cat > package/base-files/files/etc/banner <<EOF
  _____                            _        ___          __    _   
 |_   _|                          | |      | \ \        / /   | |  
   | |  _ __ ___  _ __ ___   ___  | |_ __ _| |\ \  /\  / /_ __| |_ 
   | | | '_ \` _ \| '_ \` _ \ / _ \ | __/ _\` | | \ \/  \/ /| '__| __|
  _| |_| | | | | | | | | | | (_) || || (_| | |  \  /\  / | |  | |_ 
 |_____|_| |_| |_|_| |_| |_|\___/  \__\__,_|_|   \/  \/  |_|   \__|
 ---------------------------------------------------------------------
 %D %V %C
 ---------------------------------------------------------------------
EOF

# Optimize network performance
cat >> package/base-files/files/etc/sysctl.conf <<EOF

# Network performance optimization
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 65535
net.ipv4.tcp_rmem = 10240 87380 134217728
net.ipv4.tcp_wmem = 10240 87380 134217728
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_mtu_probing = 1
EOF
