# 修改默认IP & 固件名称
sed -i 's/192.168.1.1/192.168.1.1/g' package/base-files/files/bin/config_generate
sed -i "s/hostname='.*'/hostname='OpenWrt'/g" package/base-files/files/bin/config_generate

# 修改亚瑟运行LED为绿色
# sed -i 's/&status_blue/\&status_green/g' target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6000-re-ss-01.dts

# 修改太乙启动LED为绿色，运行LED为蓝色(VIKINGYFY项目)
# sed -i 's/boot/roc/g; s/running/boot/g; s/roc/running/g' target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6010-re-cs-07.dts

# 移除要替换的包
rm -rf feeds/packages/net/alist
rm -rf feeds/luci/applications/luci-app-alist
rm -rf feeds/packages/net/adguardhome
rm -rf feeds/packages/net/ariang
rm -rf package/emortal/luci-app-athena-led
rm -rf feeds/packages/lang/golang

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# Alist & AdGuardHome & WolPlus & AriaNg & 集客无线AC控制器 & Lucky & 雅典娜LED控制 & Go
#git clone --depth=1 https://github.com/sbwml/luci-app-alist package/luci-app-alist
git_sparse_clone main https://github.com/kenzok8/small-package adguardhome luci-app-adguardhome
#git clone --depth=1 https://github.com/animegasan/luci-app-wolplus package/luci-app-wolplus
git clone --depth=1 https://github.com/sirpdboy/luci-app-advancedplus package/luci-app-advancedplus
#git_sparse_clone main https://github.com/morytyann/OpenWrt-mihomo mihomo luci-app-mihomo
git_sparse_clone main https://github.com/sirpdboy/sirpdboy-package luci-app-fileassistant
git_sparse_clone master https://github.com/immortalwrt/packages net/ariang
#git clone --depth=1 https://github.com/lwb1978/openwrt-gecoosac package/openwrt-gecoosac
#git clone --depth=1 https://github.com/gdy666/luci-app-lucky package/luci-app-lucky
#git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall package/luci-app-passwall
git_sparse_clone master https://github.com/vernesong/OpenClash luci-app-openclash
git clone --depth=1 https://github.com/sbwml/packages_lang_golang -b 23.x feeds/packages/lang/golang
git_sparse_clone main https://github.com/wafewu/Packages luci-app-wolplus

git_sparse_clone master https://github.com/kenzok8/small luci-app-ssr-plus shadowsocks-rust shadowsocksr-libev

# Themes
git clone --depth=1 https://github.com/sirpdboy/luci-theme-kucat package/luci-theme-kucat
git clone --depth=1 -b 18.06 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon

# msd_lite
git clone --depth=1 https://github.com/ximiTech/luci-app-msd_lite package/luci-app-msd_lite
git clone --depth=1 https://github.com/ximiTech/msd_lite package/msd_lite

# MosDNS
rm -rf feeds/packages/net/v2ray-geodata
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

# 修改本地时间格式
sed -i 's/os.date()/os.date("%a %Y-%m-%d %H:%M:%S")/g' package/lean/autocore/files/*/index.htm

# 修复 hostapd 报错
cp -f $GITHUB_WORKSPACE/scripts/011-fix-mbo-modules-build.patch package/network/services/hostapd/patches/011-fix-mbo-modules-build.patch

# 修复 armv8 设备 xfsprogs 报错
sed -i 's/TARGET_CFLAGS.*/TARGET_CFLAGS += -DHAVE_MAP_SYNC -D_LARGEFILE64_SOURCE/g' feeds/packages/utils/xfsprogs/Makefile

# 修改 Makefile
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/lang\/golang\/golang-package.mk/$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang-package.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHREPO/PKG_SOURCE_URL:=https:\/\/github.com/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload.github.com/g' {}

# 取消主题默认设置
find package/luci-theme-*/* -type f -name '*luci-theme-*' -print -exec sed -i '/set luci.main.mediaurlbase/d' {} \;

sed -i ':a;N;s/msgid "Wake on LAN +"\s*msgstr ""/msgid "Wake on LAN +"\nmsgstr "网络唤醒+"/g;ta' $(find ./package/luci-app-wolplus/po/zh_Hans/wolplus.po)

./scripts/feeds update -a
./scripts/feeds install -a
