"""Sensor platform for the LG ESS (local) integration."""

from __future__ import annotations

from dataclasses import dataclass

from homeassistant.components.sensor import (
    SensorDeviceClass,
    SensorEntity,
    SensorEntityDescription,
    SensorStateClass,
)
from homeassistant.config_entries import ConfigEntry
from homeassistant.const import (
    PERCENTAGE,
    UnitOfElectricCurrent,
    UnitOfElectricPotential,
    UnitOfEnergy,
    UnitOfPower,
    UnitOfTemperature,
)
from homeassistant.core import HomeAssistant
from homeassistant.helpers.entity_platform import AddEntitiesCallback

from .const import DOMAIN
from .entity import LgEssEntity


@dataclass(frozen=True, kw_only=True)
class LgEssSensorDescription(SensorEntityDescription):
    """Describes an LG ESS sensor and where its value comes from."""

    value_key: str


SENSORS: tuple[LgEssSensorDescription, ...] = (
    LgEssSensorDescription(
        key="soc",
        value_key="soc",
        translation_key="soc",
        native_unit_of_measurement=PERCENTAGE,
        device_class=SensorDeviceClass.BATTERY,
        state_class=SensorStateClass.MEASUREMENT,
    ),
    LgEssSensorDescription(
        key="soh",
        value_key="soh",
        translation_key="soh",
        native_unit_of_measurement=PERCENTAGE,
        state_class=SensorStateClass.MEASUREMENT,
        icon="mdi:heart-pulse",
    ),
    LgEssSensorDescription(
        key="power",
        value_key="power",
        translation_key="power",
        native_unit_of_measurement=UnitOfPower.WATT,
        device_class=SensorDeviceClass.POWER,
        state_class=SensorStateClass.MEASUREMENT,
    ),
    LgEssSensorDescription(
        key="current",
        value_key="current",
        translation_key="current",
        native_unit_of_measurement=UnitOfElectricCurrent.AMPERE,
        device_class=SensorDeviceClass.CURRENT,
        state_class=SensorStateClass.MEASUREMENT,
    ),
    LgEssSensorDescription(
        key="voltage",
        value_key="voltage",
        translation_key="voltage",
        native_unit_of_measurement=UnitOfElectricPotential.VOLT,
        device_class=SensorDeviceClass.VOLTAGE,
        state_class=SensorStateClass.MEASUREMENT,
    ),
    LgEssSensorDescription(
        key="temperature",
        value_key="temperature",
        translation_key="temperature",
        native_unit_of_measurement=UnitOfTemperature.CELSIUS,
        device_class=SensorDeviceClass.TEMPERATURE,
        state_class=SensorStateClass.MEASUREMENT,
    ),
    LgEssSensorDescription(
        key="cycle_count",
        value_key="cycle_count",
        translation_key="cycle_count",
        state_class=SensorStateClass.TOTAL_INCREASING,
        icon="mdi:battery-sync",
    ),
    LgEssSensorDescription(
        key="lifetime_discharge",
        value_key="lifetime_discharge",
        translation_key="lifetime_discharge",
        native_unit_of_measurement=UnitOfEnergy.KILO_WATT_HOUR,
        device_class=SensorDeviceClass.ENERGY,
        state_class=SensorStateClass.TOTAL_INCREASING,
    ),
    LgEssSensorDescription(
        key="operation_mode",
        value_key="operation_mode",
        translation_key="operation_mode",
        icon="mdi:state-machine",
    ),
    LgEssSensorDescription(
        key="wifi",
        value_key="wifi",
        translation_key="wifi",
        icon="mdi:wifi",
        entity_category=None,
    ),
    LgEssSensorDescription(
        key="cloud",
        value_key="cloud",
        translation_key="cloud",
        icon="mdi:cloud-check",
    ),
)


async def async_setup_entry(
    hass: HomeAssistant,
    entry: ConfigEntry,
    async_add_entities: AddEntitiesCallback,
) -> None:
    """Set up LG ESS (local) sensors."""
    coordinator = hass.data[DOMAIN][entry.entry_id]
    async_add_entities(
        LgEssSensor(coordinator, entry, description) for description in SENSORS
    )


class LgEssSensor(LgEssEntity, SensorEntity):
    """A single LG ESS battery sensor."""

    entity_description: LgEssSensorDescription

    def __init__(self, coordinator, entry, description: LgEssSensorDescription) -> None:
        """Initialize the sensor."""
        super().__init__(coordinator, entry)
        self.entity_description = description
        self._attr_unique_id = f"{self._base}_{description.key}"

    @property
    def native_value(self):
        """Return the current value from the coordinator data."""
        return self.coordinator.data.get(self.entity_description.value_key)
