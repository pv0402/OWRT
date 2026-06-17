#=============================================================================
# 单独使用daede+QiuSimons的dae+daed"

# 单独克隆daede文件夹
git clone --depth=1 --single-branch --branch main \
  https://github.com/kenzok8/openwrt-daede.git tmp-daede
cp -rf tmp-daede/luci-app-daede ./
rm -rf tmp-daede

echo "已集成 luci-app-daede..."

# 克隆 dae 仓库
git clone https://github.com/QiuSimons/luci-app-dae ./dae

# 克隆 daed 仓库
git clone https://github.com/QiuSimons/luci-app-daed ./daed

echo "已集成 QiuSimons版 dae/daed"

#=============================================================================
#lucky纯数字版本号更新+离线补丁
# 补丁命名示范：lucky_3.0.0_Linux_arm64_wanji.tar.gz

# 全局路径定义 
patches_dir="$GITHUB_WORKSPACE/patches"
lucky_makefile="./lucky/Makefile"

# 同步版本号（必须和更新补丁配合，否则编译失败）
if [ -f "$lucky_makefile" ] && [ -d "$patches_dir" ]; then
    latest_patch=$(ls "$patches_dir" 2>/dev/null | grep -E '^lucky_.*_Linux_.*_wanji\.tar\.gz$' | sort -V | tail -1)
    if [ -n "$latest_patch" ]; then
        patch_version=$(echo "$latest_patch" | sed -n 's/^lucky_\(.*\)_Linux_.*$/\1/p')
        if [ -n "$patch_version" ]; then
            echo "检测到补丁版本: $patch_version"
            if grep -q "^PKG_VERSION:=" "$lucky_makefile"; then
                old_ver=$(grep -Po '^PKG_VERSION:=\K.*' "$lucky_makefile")
                sed -i "s/^PKG_VERSION:=.*/PKG_VERSION:=$patch_version/" "$lucky_makefile"
                echo "PKG_VERSION 已从 $old_ver 更新为 $patch_version"
            fi
        fi
    fi
fi

# 离线补丁处理
if [ -f "$lucky_makefile" ]; then
    if [ -d "$patches_dir" ]; then
        latest_patch=$(ls "$patches_dir" 2>/dev/null | grep -E '^lucky_.*_Linux_.*_wanji\.tar\.gz$' | sort -V | tail -1)
        if [ -n "$latest_patch" ]; then
            patch_version=$(echo "$latest_patch" | sed -n 's/^lucky_\(.*\)_Linux_.*$/\1/p')
            if [ -n "$patch_version" ]; then
                echo "发现离线补丁: $latest_patch，版本 $patch_version，将替换下载。"

                # 复制补丁到 OpenWrt 的 dl 目录
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
                    # 极简目标文件名：直接使用 patch_version，去掉 _wanji
                    patch_line="${TAB}[ -f \$(DL_DIR)/lucky_${patch_version}_Linux_\$(LUCKY_ARCH)_wanji.tar.gz ] && install -Dm644 \$(DL_DIR)/lucky_${patch_version}_Linux_\$(LUCKY_ARCH)_wanji.tar.gz \$(PKG_BUILD_DIR)/lucky_${patch_version}_Linux_\$(LUCKY_ARCH).tar.gz"
                    # 如果不同步更新版本号，则需要从makefile提取版本号，使用下面的命令
                    #patch_line="${TAB}[ -f \$(DL_DIR)/lucky_${patch_version}_Linux_\$(LUCKY_ARCH)_wanji.tar.gz ] && install -Dm644 \$(DL_DIR)/lucky_${patch_version}_Linux_\$(LUCKY_ARCH)_wanji.tar.gz \$(PKG_BUILD_DIR)/\$(PKG_NAME)_\$(PKG_VERSION)_Linux_\$(LUCKY_ARCH).tar.gz"
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

#========================================================================

# lucky只更新离线补丁，不变更版本号
# 补丁包命名格式：lucky_.*_Linux_.*_wanji.tar.gz

# 全局路径定义 
patches_dir="$GITHUB_WORKSPACE/patches"
lucky_makefile="./lucky/Makefile"

# 离线补丁处理
if [ -f "$lucky_makefile" ]; then
    if [ -d "$patches_dir" ]; then
        latest_patch=$(ls "$patches_dir" 2>/dev/null | grep -E '^lucky_.*_Linux_.*_wanji\.tar\.gz$' | sort -V | tail -1)
        if [ -n "$latest_patch" ]; then
            patch_version=$(echo "$latest_patch" | sed -n 's/^lucky_\(.*\)_Linux_.*$/\1/p')
            if [ -n "$patch_version" ]; then
                echo "发现离线补丁: $latest_patch，版本 $patch_version，将替换下载。"

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

#========================================================================
#passwall
#========================================================================
#GENERAL.txt配置

CONFIG_PACKAGE_luci-app-passwall=y
### PassWall配置项 ###
# CONFIG_PACKAGE_luci-app-passwall_Iptables_Transparent_Proxy is not set
CONFIG_PACKAGE_luci-app-passwall_Nftables_Transparent_Proxy=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Geoview=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Haproxy=y
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Hysteria is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_NaiveProxy is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Libev_Client is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Libev_Server is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Client is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Server is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ShadowsocksR_Libev_Client is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ShadowsocksR_Libev_Server is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadow_TLS is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Simple_Obfs is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_SingBox is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Trojan_Plus is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_tuic_client is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Geodata is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin is not set
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray=y
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray_Plugin is not set
#========================================================================

#PRIVATE.sh配置

###编译最新PassWall###

# 移除 OpenWrt Feeds 自带的核心库
rm -rf ../feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
git clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages ./passwall-packages

# 移除 OpenWrt Feeds 过时的LuCI版本
rm -rf ../feeds/luci/applications/luci-app-passwall
git clone https://github.com/Openwrt-Passwall/openwrt-passwall ./passwall-luci


# 清理 PassWall 的 chnlist 规则文件
echo "baidu.com"  > ./passwall-luci/luci-app-passwall/root/usr/share/passwall/rules/chnlist

#========================================================================
