#PRIVATE.sh
#==================== dae/daed ====================
# 删除官方 feeds 中的四个目标目录
rm -rf ../feeds/luci/applications/luci-app-dae
rm -rf ../feeds/luci/applications/luci-app-daed
rm -rf ../feeds/packages/net/dae
rm -rf ../feeds/packages/net/daed

# 使用kenzok8编译的dae+daed+daede(项目仓库All in One)
echo "拉取 openwrt-daede 仓库..."
git clone --depth 1 https://github.com/kenzok8/openwrt-daede.git ./openwrt-daede
echo "openwrt-daede 已放置到package目录。"

#==================== 集成 lucky+更新补丁+同步版本号 ====================
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

# 全局路径定义 
patches_dir="$GITHUB_WORKSPACE/patches"
lucky_makefile="./lucky/Makefile"

# 自动同步版本号和 release（必须和更新补丁配合，否则编译失败）
# 补丁路径：编译仓库根目录下patches文件夹内
# 补丁文件名格式：lucky_<version>-r<release>_Linux_<arch>_wanji.tar.gz
# 例如：lucky_3.0.0-r6_Linux_arm64_wanji.tar.gz
if [ -f "$lucky_makefile" ] && [ -d "$patches_dir" ]; then
    latest_patch=$(ls "$patches_dir" 2>/dev/null | grep -E '^lucky_.*-r[0-9]*_Linux_.*_wanji\.tar\.gz$' | sort -V | tail -1)
    if [ -n "$latest_patch" ]; then
        patch_version=$(echo "$latest_patch" | sed -n 's/^lucky_\(.*\)-r\([0-9]*\)_Linux_.*$/\1/p')
        patch_release=$(echo "$latest_patch" | sed -n 's/^lucky_.*-r\([0-9]*\)_Linux_.*$/\1/p')
        if [ -n "$patch_version" ]; then
            echo "检测到补丁: $latest_patch → 版本 $patch_version, release $patch_release"
            if grep -q "^PKG_VERSION:=" "$lucky_makefile"; then
                old_ver=$(grep -Po '^PKG_VERSION:=\K.*' "$lucky_makefile")
                sed -i "s/^PKG_VERSION:=.*/PKG_VERSION:=$patch_version/" "$lucky_makefile"
                echo "PKG_VERSION 已从 $old_ver 更新为 $patch_version"
            fi
            if [ -n "$patch_release" ] && grep -q "^PKG_RELEASE:=" "$lucky_makefile"; then
                old_rel=$(grep -Po '^PKG_RELEASE:=\K.*' "$lucky_makefile")
                sed -i "s/^PKG_RELEASE:=.*/PKG_RELEASE:=$patch_release/" "$lucky_makefile"
                echo "PKG_RELEASE 已从 $old_rel 更新为 $patch_release"
            fi
        else
            echo "警告：无法从 $latest_patch 中提取版本号，跳过版本更新。" >&2
        fi
    else
        echo "未找到任何 lucky 补丁文件，版本号保持原样。"
    fi
else
    [ ! -f "$lucky_makefile" ] && echo "警告：lucky Makefile 未找到，跳过版本更新。" >&2
    [ ! -d "$patches_dir" ] && echo "patches 目录不存在，跳过版本更新。"
fi

# 离线补丁处理
if [ -f "$lucky_makefile" ]; then
    if [ -d "$patches_dir" ]; then
        latest_patch=$(ls "$patches_dir" 2>/dev/null | grep -E '^lucky_.*-r[0-9]*_Linux_.*_wanji\.tar\.gz$' | sort -V | tail -1)
        if [ -n "$latest_patch" ]; then
            patch_version=$(echo "$latest_patch" | sed -n 's/^lucky_\(.*\)-r\([0-9]*\)_Linux_.*$/\1/p')
            patch_release=$(echo "$latest_patch" | sed -n 's/^lucky_.*-r\([0-9]*\)_Linux_.*$/\1/p')
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
                    patch_line="${TAB}[ -f \$(DL_DIR)/lucky_${patch_version}-r${patch_release}_Linux_\$(LUCKY_ARCH)_wanji.tar.gz ] && install -Dm644 \$(DL_DIR)/lucky_${patch_version}-r${patch_release}_Linux_\$(LUCKY_ARCH)_wanji.tar.gz \$(PKG_BUILD_DIR)/lucky_${patch_version}_Linux_\$(LUCKY_ARCH).tar.gz"
                    # 如果不同步更新版本号，则需要从makefile提取版本号，使用下面的命令，仅适用补丁文件名格式：lucky_<version>-r<release>_Linux_<arch>_wanji.tar.gz
                    #patch_line="${TAB}[ -f \$(DL_DIR)/lucky_${patch_version}-r${patch_release}_Linux_\$(LUCKY_ARCH)_wanji.tar.gz ] && install -Dm644 \$(DL_DIR)/lucky_${patch_version}-r${patch_release}_Linux_\$(LUCKY_ARCH)_wanji.tar.gz \$(PKG_BUILD_DIR)/\$(PKG_NAME)_\$(PKG_VERSION)_Linux_\$(LUCKY_ARCH).tar.gz"                    
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


echo "==================== 当前工作目录 ===================="
pwd
echo ""

echo "==================== package/ 下一级子目录（即所有 OpenWrt 包） ===================="
find . -maxdepth 1 -type d ! -path . | sort

echo ""

echo "=========================================================="
#find . -maxdepth 3 -type f -o -type d | sort