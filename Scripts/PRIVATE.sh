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

#==================== 集成 lucky ====================
echo "处理 lucky..."

# 删除 feeds 中的旧包（避免冲突）
rm -rf ../feeds/luci/applications/luci-app-lucky 2>/dev/null
rm -rf ../feeds/packages/net/lucky 2>/dev/null

# 克隆包含 luci 和 lucky 定义文件的仓库
git clone --depth 1 --single-branch --branch main \
  https://github.com/gdy666/luci-app-lucky.git ./luci-app-lucky-tmp

# 把子目录拆分成平级的两个包
if [ -d "./luci-app-lucky-tmp/lucky" ]; then
    cp -rf ./luci-app-lucky-tmp/lucky ./lucky
fi
if [ -d "./luci-app-lucky-tmp/luci-app-lucky" ]; then
    cp -rf ./luci-app-lucky-tmp/luci-app-lucky ./luci-app-lucky
fi

# 删除克隆下来的临时目录
rm -rf ./luci-app-lucky-tmp

# 修改 lucky 默认配置（禁用 enabled 和 logger）
local lucky_conf="./lucky/files/luckyuci"
if [ -f "$lucky_conf" ]; then
    sed -i "s/option enabled '1'/option enabled '0'/g" "$lucky_conf"
    sed -i "s/option logger '1'/option logger '0'/g" "$lucky_conf"
    echo "lucky 默认配置已修改。"
fi

# 可选：如果仓库根目录 patches/ 下有离线补丁，则插入本地安装命令
local patches_dir="$GITHUB_WORKSPACE/patches"
local lucky_makefile="./lucky/Makefile"
if [ -d "$patches_dir" ] && [ -f "$lucky_makefile" ]; then
    local latest_patch=$(ls "$patches_dir" 2>/dev/null | grep -E '^lucky_.*_Linux_.*_wanji\.tar\.gz$' | sort -V | tail -1)
    if [ -n "$latest_patch" ]; then
        local version=$(echo "$latest_patch" | sed -n 's/^lucky_\(.*\)_Linux_.*$/\1/p')
        if [ -n "$version" ]; then
            echo "发现 lucky 离线补丁: $latest_patch，版本 $version，将替换下载。"
            local patch_line="\\t[ -f \$(TOPDIR)/../patches/lucky_${version}_Linux_\$(LUCKY_ARCH)_wanji.tar.gz ] && install -Dm644 \$(TOPDIR)/../patches/lucky_${version}_Linux_\$(LUCKY_ARCH)_wanji.tar.gz \$(PKG_BUILD_DIR)/\$(PKG_NAME)_\$(PKG_VERSION)_Linux_\$(LUCKY_ARCH).tar.gz"
            if grep -q "Build/Prepare" "$lucky_makefile"; then
                sed -i "/Build\\/Prepare/a\\$patch_line" "$lucky_makefile"
                sed -i '/wget/d' "$lucky_makefile"
                echo "lucky Makefile 已插入本地补丁命令。"
            fi
        fi
    fi
fi

echo "lucky 集成完成（保留原始版本，运行时由程序内部判断更新）。"

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