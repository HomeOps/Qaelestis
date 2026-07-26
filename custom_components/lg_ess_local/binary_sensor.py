"""Binary sensor platform for the LG ESS (local) integration."""

from __future__ import annotations

from homeassistant.components.binary_sensor import (
    BinarySensorDeviceClass,
    BinarySensorEntity,
)
from homeassistant.config_entries import ConfigEntry
from homeassistant.core import HomeAssistant
from homeassistant.helpers.entity_platform import AddEntitiesCallback

from .const import DOMAIN
from .entity import LgEssEntity


async def async_setup_entry(
    hass: HomeAssistant,
    entry: ConfigEntry,
    async_add_entities: AddEntitiesCallback,
) -> None:
    """Set up the LG ESS (local) binary sensors."""
    coordinator = hass.data[DOMAIN][entry.entry_id]
    async_add_entities([LgEssChargingSensor(coordinator, entry)])


class LgEssChargingSensor(LgEssEntity, BinarySensorEntity):
    """True when the battery is charging (BMS current > 0)."""

    _attr_translation_key = "charging"
    _attr_device_class = BinarySensorDeviceClass.BATTERY_CHARGING

    def __init__(self, coordinator, entry) -> None:
        """Initialize the charging binary sensor."""
        super().__init__(coordinator, entry)
        self._attr_unique_id = f"{self._base}_charging"

    @property
    def is_on(self) -> bool | None:
        """Return True if charging, None if unknown."""
        current = self.coordinator.data.get("current")
        if current is None:
            return None
        return current > 0.1
