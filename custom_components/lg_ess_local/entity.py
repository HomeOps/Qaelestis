"""Base entity for the LG ESS (local) integration."""

from __future__ import annotations

from homeassistant.config_entries import ConfigEntry
from homeassistant.helpers.device_registry import DeviceInfo
from homeassistant.helpers.update_coordinator import CoordinatorEntity

from .const import CONF_MAC, DOMAIN
from .coordinator import LgEssLocalCoordinator


class LgEssEntity(CoordinatorEntity[LgEssLocalCoordinator]):
    """Common device wiring for all LG ESS (local) entities."""

    _attr_has_entity_name = True

    def __init__(self, coordinator: LgEssLocalCoordinator, entry: ConfigEntry) -> None:
        """Initialize the entity and attach it to the battery device."""
        super().__init__(coordinator)
        mac = entry.data.get(CONF_MAC)
        self._base = mac or coordinator.host
        self._attr_device_info = DeviceInfo(
            identifiers={(DOMAIN, self._base)},
            name="LG ESS Battery",
            manufacturer="LG Energy Solution",
            model="RESU (RMD local)",
            configuration_url=f"http://{coordinator.host}",
            connections={("mac", mac)} if mac else set(),
        )
