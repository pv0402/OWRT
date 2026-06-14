#PRIVATE.sh
#==================== 替换 dae/daed 为第三方版本 ====================
#echo "替换 dae/daed 为 QiuSimons 的 Kix 分支..."

# 1. 删除官方 feeds 中的四个目标目录
rm -rf ../feeds/luci/applications/luci-app-dae
rm -rf ../feeds/luci/applications/luci-app-daed
rm -rf ../feeds/packages/net/dae
rm -rf ../feeds/packages/net/daed

# 2. 克隆 dae 仓库
#git clone https://github.com/QiuSimons/luci-app-dae ./dae

# 3. 克隆 daed 仓库
#git clone https://github.com/QiuSimons/luci-app-daed ./daed

#echo "第三方 dae/daed 包替换完成。"

#echo ">> 集成 luci-app-daede..."

# 拉取 kenzok8 的 daede 仓库
echo "拉取 openwrt-daede 仓库..."
git clone --depth 1 https://github.com/kenzok8/openwrt-daede.git ./openwrt-daede
echo "openwrt-daede 已放置到package目录。"

# 替换 update-geo.sh 中的下载源为 Loyalsoldier 版本
UPDATE_GEO_SH="./openwrt-daede/luci-app-daede/root/usr/share/luci-app-daede/update-geo.sh"
if [ -f "$UPDATE_GEO_SH" ]; then
    sed -i 's|https://github.com/v2fly/geoip/releases/latest/download/geoip.dat|https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat|g' "$UPDATE_GEO_SH"
    sed -i 's|https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat|https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat|g' "$UPDATE_GEO_SH"
    echo "update-geo.sh 下载源已替换为 Loyalsoldier。"
else
    echo "警告：未找到 update-geo.sh 文件，跳过修改。"
fi

#find ./openwrt-daede -maxdepth 2 -type f -o -type d | sort

#git clone --depth=1 --single-branch --branch main \
#  https://github.com/kenzok8/openwrt-daede.git tmp-daede
#cp -rf tmp-daede/luci-app-daede ./
#rm -rf tmp-daede

#==================== 集成 lucky ====================
echo "处理 lucky..."

# 克隆仓库
git clone --depth 1 --single-branch --branch main \
  https://github.com/gdy666/luci-app-lucky.git ./luci-app-lucky-tmp

# 拆分子目录
if [ -d "./luci-app-lucky-tmp/lucky" ]; then
    cp -rf ./luci-app-lucky-tmp/lucky ./lucky
fi
if [ -d "./luci-app-lucky-tmp/luci-app-lucky" ]; then
    cp -rf ./luci-app-lucky-tmp/luci-app-lucky ./luci-app-lucky
fi
rm -rf ./luci-app-lucky-tmp

# 修改默认配置（与版本无关，始终执行）
lucky_conf="./lucky/files/luckyuci"
if [ -f "$lucky_conf" ]; then
    sed -i "s/option enabled '1'/option enabled '0'/g" "$lucky_conf"
    sed -i "s/option logger '1'/option logger '0'/g" "$lucky_conf"
    echo "lucky 默认配置已修改。"
fi

echo "lucky 集成完成。"

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
#find . -maxdepth 3 -type f -o -type d | sort