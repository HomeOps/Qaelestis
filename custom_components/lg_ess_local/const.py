"""Constants for the LG ESS (local) integration."""

from __future__ import annotations

DOMAIN = "lg_ess_local"

DEFAULT_NAME = "LG ESS"
DEFAULT_SCAN_INTERVAL = 30

# Config keys
CONF_MAC = "mac"

# Local RMD web-portal endpoints (HTTP, port 80, no auth)
ENDPOINT_BMS = "/getbmsdata"        # HTML table: SOC/SOH/Current/voltages/temps...
ENDPOINT_SERVER = "/getserverst"    # JSON: operation mode + connectivity
ENDPOINT_APINFO = "/configapinfo"   # JSON: SoftAP ssid (RESU_<MAC>) -> identity
