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

# 删除 feeds 旧包
rm -rf ../feeds/luci/applications/luci-app-lucky 2>/dev/null
rm -rf ../feeds/packages/net/lucky 2>/dev/null

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

# 自动检测 patches/ 目录下的补丁包，提取版本号并更新 Makefile
patches_dir="$GITHUB_WORKSPACE/patches"
lucky_makefile="./lucky/Makefile"

if [ -d "$patches_dir" ] && [ -f "$lucky_makefile" ]; then
    # 找到版本号最大的补丁包
    latest_patch=$(ls "$patches_dir" 2>/dev/null | grep -E '^lucky_.*_Linux_.*_wanji\.tar\.gz$' | sort -V | tail -1)
    
    if [ -n "$latest_patch" ]; then
        version=$(echo "$latest_patch" | sed -n 's/^lucky_\(.*\)_Linux_.*$/\1/p')
        if [ -n "$version" ]; then
            echo "发现 lucky 离线补丁: $latest_patch，将版本更新为 $version"

            # 1. 更新 Makefile 中的 PKG_VERSION
            if grep -q "^PKG_VERSION:=" "$lucky_makefile"; then
                sed -i "s/^PKG_VERSION:=.*/PKG_VERSION:=$version/" "$lucky_makefile"
                echo "lucky 版本号已自动更新为 $version"
            fi

            # 2. 插入本地补丁安装命令，删除 wget 下载
            patch_line="\\t[ -f \$(TOPDIR)/../patches/lucky_${version}_Linux_\$(LUCKY_ARCH)_wanji.tar.gz ] && install -Dm644 \$(TOPDIR)/../patches/lucky_${version}_Linux_\$(LUCKY_ARCH)_wanji.tar.gz \$(PKG_BUILD_DIR)/\$(PKG_NAME)_\$(PKG_VERSION)_Linux_\$(LUCKY_ARCH).tar.gz"
            if grep -q "Build/Prepare" "$lucky_makefile"; then
                sed -i "/Build\\/Prepare/a\\$patch_line" "$lucky_makefile"
                sed -i '/wget/d' "$lucky_makefile"
                echo "已插入本地补丁安装命令。"
            fi
        fi
    else
        echo "未找到任何 lucky 离线补丁，版本号保持不变。"
    fi
else
    echo "patches 目录或 lucky Makefile 不存在，跳过离线补丁处理。"
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