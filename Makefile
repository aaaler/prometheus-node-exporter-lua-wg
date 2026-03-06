#
# OpenWrt package for WireGuard/Amnezia WG collector (prometheus-node-exporter-lua).
# Build with OpenWrt SDK: make V=s
#

include $(TOPDIR)/rules.mk

PKG_NAME:=prometheus-node-exporter-lua-wireguard
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_MAINTAINER:=Prometheus Node Exporter Lua WG contributors
PKG_LICENSE:=Apache-2.0

PKGARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/prometheus-node-exporter-lua-wireguard
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Prometheus node exporter (WireGuard/Amnezia WG collector)
  DEPENDS:=prometheus-node-exporter-lua
  PKGARCH:=all
endef

define Package/prometheus-node-exporter-lua-wireguard/description
  WireGuard and Amnezia WG latest handshake collector for prometheus-node-exporter-lua.
  Exports wg_latest_handshake_seconds from wg and amneziawg CLIs.
endef

define Package/prometheus-node-exporter-lua-wireguard/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/prometheus-collectors
	$(INSTALL_BIN) ./wireguard.lua $(1)/usr/lib/lua/prometheus-collectors/
endef

$(eval $(call BuildPackage,prometheus-node-exporter-lua-wireguard))
