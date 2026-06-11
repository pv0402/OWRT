#PRIVATE.sh
#==================== 替换 dae/daed 为第三方版本 ====================
echo "替换 dae/daed 为 QiuSimons 的 Kix 分支..."

# 1. 精确删除官方 feeds 中的四个目标目录（不会误删其他包）
rm -rf ../feeds/luci/applications/luci-app-dae
rm -rf ../feeds/luci/applications/luci-app-daed
rm -rf ../feeds/packages/net/dae
rm -rf ../feeds/packages/net/daed

# 2. 清理可能已存在的旧包目录（避免冲突）
rm -rf dae luci-app-dae daed luci-app-daed 2>/dev/null

# 3. 克隆 luci-app-dae 仓库到临时目录，提取子包到当前目录
git clone --depth=1 --single-branch --branch kix \
  https://github.com/QiuSimons/luci-app-dae.git tmp-dae
mv tmp-dae/dae           dae
mv tmp-dae/luci-app-dae  luci-app-dae
rm -rf tmp-dae

# 4. 克隆 luci-app-daed 仓库到临时目录，提取子包到当前目录
git clone --depth=1 --single-branch --branch kix \
  https://github.com/QiuSimons/luci-app-daed.git tmp-daed
mv tmp-daed/daed          daed
mv tmp-daed/luci-app-daed luci-app-daed
rm -rf tmp-daed

echo "第三方 dae/daed 包替换完成。"

echo ">> 集成 luci-app-daede..."
git clone --depth=1 --single-branch --branch main \
  https://github.com/kenzok8/openwrt-daede.git tmp-daede
cp -rf tmp-daede/luci-app-daede ./
rm -rf tmp-daede

echo "==================== 当前工作目录 ===================="
pwd
echo ""

echo "==================== package/ 下一级子目录（即所有 OpenWrt 包） ===================="
find . -maxdepth 1 -type d ! -path . | sort

echo ""

echo "=========================================================="