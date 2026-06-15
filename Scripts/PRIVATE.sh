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

# 5. 离线补丁处理（复制到 dl 目录，并修改 Makefile）
patches_dir="$GITHUB_WORKSPACE/patches"
lucky_makefile="./lucky/Makefile"

if [ -f "$lucky_makefile" ]; then
    if [ -d "$patches_dir" ]; then
        latest_patch=$(ls "$patches_dir" 2>/dev/null | grep -E '^lucky_.*_Linux_.*_wanji\.tar\.gz$' | sort -V | tail -1)
        if [ -n "$latest_patch" ]; then
            patch_version=$(echo "$latest_patch" | sed -n 's/^lucky_\(.*\)_Linux_.*$/\1/p')
            if [ -n "$patch_version" ]; then
                echo "发现离线补丁: $latest_patch，版本 $patch_version，将替换下载。"

                # 复制补丁到 OpenWrt 的 dl 目录（当前目录是 package/，../dl 就是 wrt/dl）
                dl_dir="../dl"
                mkdir -p "$dl_dir"
                if cp "$patches_dir/$latest_patch" "$dl_dir/"; then
                    echo "补丁文件已复制到 $dl_dir/"
                else
                    echo "错误：无法复制补丁文件到 $dl_dir/" >&2
                    return 1 2>/dev/null || exit 1
                fi

                if ! grep -q "Build/Prepare" "$lucky_makefile"; then
                    echo "警告：lucky Makefile 中未找到 'Build/Prepare'，无法插入补丁命令。" >&2
                else
                    TAB=$'\t'
                    # 插入的命令：从 $(DL_DIR) 获取补丁文件
                    patch_line="${TAB}[ -f \$(DL_DIR)/lucky_${patch_version}_Linux_\$(LUCKY_ARCH)_wanji.tar.gz ] && install -Dm644 \$(DL_DIR)/lucky_${patch_version}_Linux_\$(LUCKY_ARCH)_wanji.tar.gz \$(PKG_BUILD_DIR)/\$(PKG_NAME)_\$(PKG_VERSION)_Linux_\$(LUCKY_ARCH).tar.gz"
                    sed -i "/Build\\/Prepare/a\\$patch_line" "$lucky_makefile"
                    sed -i '/wget/d' "$lucky_makefile"
                    echo "已插入本地补丁安装命令，并移除 wget 下载。"
                fi
            else
                echo "警告：无法从 $latest_patch 中提取版本号，跳过补丁处理。" >&2
            fi
        else
            echo "未找到任何 lucky 离线补丁，保留 wget 下载。"
        fi
    else
        echo "patches 目录不存在，跳过补丁处理。"
    fi
else
    echo "警告：lucky Makefile 未找到，无法进行补丁操作。" >&2
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