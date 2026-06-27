"""Data update coordinator for the LG ESS (local) integration.

Talks to the LG ESS / RESU RMD web portal over HTTP (port 80, no auth):
  * /getbmsdata   - HTML table of BMS values (SOC, SOH, current, voltages, temps)
  * /getserverst  - JSON of operating mode + connectivity

This path is used because the LG /v1 HTTPS API (port 443) is disabled on the
station interface of many units, so pyess / ha-lg-ess cannot reach them. The
port-80 portal, however, serves the data unauthenticated.
"""

from __future__ import annotations

import asyncio
import logging
import re
from datetime import timedelta

from homeassistant.config_entries import ConfigEntry
from homeassistant.core import HomeAssistant
from homeassistant.helpers.aiohttp_client import async_get_clientsession
from homeassistant.helpers.update_coordinator import DataUpdateCoordinator, UpdateFailed

from .const import (
    DEFAULT_SCAN_INTERVAL,
    DOMAIN,
    ENDPOINT_BMS,
    ENDPOINT_SERVER,
)

_LOGGER = logging.getLogger(__name__)

# <td>Key</td><td>Value</td> rows in /getbmsdata
_ROW_RE = re.compile(r"<td>([^<]+)</td><td>([^<]*)</td>")
# leading signed number inside a value cell ("98.72%", "-5.700A", "34.0&#8451")
_NUM_RE = re.compile(r"-?\d+(?:\.\d+)?")


def _num(value: str | None) -> float | None:
    """Extract the leading (signed) number from a value cell."""
    if value is None:
        return None
    match = _NUM_RE.search(value)
    return float(match.group()) if match else None


class LgEssLocalCoordinator(DataUpdateCoordinator[dict]):
    """Polls the RMD portal and exposes a normalized data dict."""

    def __init__(self, hass: HomeAssistant, host: str, entry: ConfigEntry) -> None:
        """Initialize the coordinator."""
        super().__init__(
            hass,
            _LOGGER,
            name=DOMAIN,
            update_interval=timedelta(seconds=DEFAULT_SCAN_INTERVAL),
        )
        self._host = host
        self._session = async_get_clientsession(hass)
        self.entry = entry

    @property
    def host(self) -> str:
        """Return the device host/IP."""
        return self._host

    async def _get_text(self, path: str) -> str:
        async with asyncio.timeout(10):
            resp = await self._session.get(f"http://{self._host}{path}")
            resp.raise_for_status()
            return await resp.text()

    async def _get_json(self, path: str) -> dict:
        async with asyncio.timeout(10):
            resp = await self._session.get(f"http://{self._host}{path}")
            resp.raise_for_status()
            # the portal returns application/json without a strict content-type
            return await resp.json(content_type=None)

    async def _async_update_data(self) -> dict:
        """Fetch and normalize the latest data."""
        try:
            bms_html = await self._get_text(ENDPOINT_BMS)
            server = await self._get_json(ENDPOINT_SERVER)
        except Exception as err:  # noqa: BLE001 - surface as UpdateFailed
            raise UpdateFailed(f"Error talking to LG ESS at {self._host}: {err}") from err

        rows = {k.strip(): v.strip() for k, v in _ROW_RE.findall(bms_html)}

        ipi_v = _num(rows.get("IPI_Voltage"))
        ipi_a = _num(rows.get("IPI_Current"))
        lifetime_wh = _num(rows.get("LifeTimeDischargeEnergy"))

        data: dict = {
            "soc": _num(rows.get("SOC")),
            "soh": _num(rows.get("SOH")),
            "current": _num(rows.get("Current")),
            "voltage": _num(rows.get("BPI_Voltage")),
            "temperature": _num(rows.get("AvgTemperature")),
            "cycle_count": _num(rows.get("CycleCount")),
            "lifetime_discharge": (
                round(lifetime_wh / 1000, 1) if lifetime_wh is not None else None
            ),
            # DC power at the inverter interface; positive = charging on this unit
            "power": (
                round(ipi_v * ipi_a) if ipi_v is not None and ipi_a is not None else None
            ),
            "operation_mode": server.get("bmsOperationMode"),
            "wifi": server.get("wifiConnection"),
            "cloud": server.get("serverConnection"),
        }
        return data
