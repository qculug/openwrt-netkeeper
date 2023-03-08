#
# Copyright (C) 2021-2022 Roald Clark <roaldclark@gmail.com>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=netkeeper
PKG_VERSION:=1.8.1
PKG_RELEASE:=8

#PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-openwrt-master
#PKG_SOURCE:=master.zip
#PKG_SOURCE_URL:=https://github.com/qculug/netkeeper-openwrt/archive/
#PKG_HASH:=e9bc77d48f825cd6d99826fa92d9cfeeee2afc1097eb7f486e552ece3982fdae

PKG_MAINTAINER:=Roald Clark <roaldclark@gmail.com>

PKG_LICENSE:=GPL-3.0-only
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/netkeeper
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Use NetKeeper by rp-pppoe-server
	URL:=https://github.com/qculug/openwrt-netkeeper
	DEPENDS:=+rp-pppoe-server
	PKGARCH:=all
endef

define Package/netkeeper/description
	Obtain a random username generated by NetKeeper through rp-pppoe-server.
endef

define Build/Compile
endef

define Package/netkeeper/install
	$(INSTALL_DIR) $(1)/usr/bin/
	$(INSTALL_BIN) ./files/netkeeper-init.sh $(1)/usr/bin/netkeeper-init
	$(INSTALL_DIR) $(1)/usr/lib/netkeeper/
	$(INSTALL_BIN) ./files/netkeeper.sh $(1)/usr/lib/netkeeper
	$(INSTALL_DIR) $(1)/etc/init.d/
	$(INSTALL_BIN) ./files/netkeeper.init $(1)/etc/init.d/netkeeper
	$(INSTALL_DIR) $(1)/etc/uci-defaults/
	$(INSTALL_DATA) ./files/netkeeper.default $(1)/etc/uci-defaults/99-netkeeper
endef

$(eval $(call BuildPackage,netkeeper))
