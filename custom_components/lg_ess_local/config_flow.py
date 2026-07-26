"""Config flow for the LG ESS (local) integration."""

from __future__ import annotations

import asyncio
import re
from typing import Any

import voluptuous as vol

from homeassistant.config_entries import ConfigFlow, ConfigFlowResult
from homeassistant.const import CONF_HOST
from homeassistant.helpers.aiohttp_client import async_get_clientsession

from .const import CONF_MAC, DEFAULT_NAME, DOMAIN, ENDPOINT_APINFO, ENDPOINT_BMS

STEP_USER_DATA_SCHEMA = vol.Schema({vol.Required(CONF_HOST): str})

_SSID_MAC_RE = re.compile(r"RESU_([0-9A-Fa-f]{12})")


async def _validate_host(hass, host: str) -> dict[str, str | None]:
    """Confirm the RMD portal answers and derive the device MAC."""
    session = async_get_clientsession(hass)
    async with asyncio.timeout(10):
        # the BMS endpoint must respond for the integration to be useful
        resp = await session.get(f"http://{host}{ENDPOINT_BMS}")
        resp.raise_for_status()
        await resp.text()
        # identity: SoftAP ssid is RESU_<MAC>
        cfg = await session.get(f"http://{host}{ENDPOINT_APINFO}")
        cfg.raise_for_status()
        apinfo = await cfg.json(content_type=None)

    mac: str | None = None
    match = _SSID_MAC_RE.match(str(apinfo.get("ssid", "")))
    if match:
        hexmac = match.group(1).lower()
        mac = ":".join(hexmac[i : i + 2] for i in range(0, 12, 2))
    return {CONF_MAC: mac}


class LgEssLocalConfigFlow(ConfigFlow, domain=DOMAIN):
    """Handle a config flow for LG ESS (local)."""

    VERSION = 1

    async def async_step_user(
        self, user_input: dict[str, Any] | None = None
    ) -> ConfigFlowResult:
        """Handle the initial step."""
        errors: dict[str, str] = {}
        if user_input is not None:
            host = user_input[CONF_HOST]
            try:
                info = await _validate_host(self.hass, host)
            except Exception:  # noqa: BLE001
                errors["base"] = "cannot_connect"
            else:
                await self.async_set_unique_id(info[CONF_MAC] or host)
                self._abort_if_unique_id_configured()
                return self.async_create_entry(
                    title=f"{DEFAULT_NAME} ({host})",
                    data={CONF_HOST: host, CONF_MAC: info[CONF_MAC]},
                )

        return self.async_show_form(
            step_id="user", data_schema=STEP_USER_DATA_SCHEMA, errors=errors
        )
