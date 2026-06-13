#PRIVATE.sh
#==================== 替换 dae/daed 为第三方版本 ====================
echo "替换 dae/daed 为 QiuSimons 的 Kix 分支..."

# 1. 删除官方 feeds 中的四个目标目录
rm -rf ../feeds/luci/applications/luci-app-dae
rm -rf ../feeds/luci/applications/luci-app-daed
rm -rf ../feeds/packages/net/dae
rm -rf ../feeds/packages/net/daed

# 2. 克隆 dae 仓库
git clone https://github.com/QiuSimons/luci-app-dae ./dae

# 3. 克隆 daed 仓库
git clone https://github.com/QiuSimons/luci-app-daed ./daed

echo "第三方 dae/daed 包替换完成。"

echo ">> 集成 luci-app-daede..."
git clone --depth=1 --single-branch --branch main \
  https://github.com/kenzok8/openwrt-daede.git tmp-daede
cp -rf tmp-daede/luci-app-daede ./
rm -rf tmp-daede

###编译最新PassWall###

# 移除 OpenWrt Feeds 自带的核心库
rm -rf ../feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
git clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages ./passwall-packages

# 移除 OpenWrt Feeds 过时的LuCI版本
rm -rf ../feeds/luci/applications/luci-app-passwall
git clone https://github.com/Openwrt-Passwall/openwrt-passwall ./passwall-luci


# 清理 PassWall 的 chnlist 规则文件
echo "baidu.com"  > ./passwall-luci/luci-app-passwall/root/usr/share/passwall/rules/chnlist

echo "==================== 当前工作目录 ===================="
pwd
echo ""

echo "==================== package/ 下一级子目录（即所有 OpenWrt 包） ===================="
find . -maxdepth 1 -type d ! -path . | sort

echo ""

echo "=========================================================="