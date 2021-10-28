#!/usr/bin/env python3

from typing import NamedTuple, Dict, Any
import json
import sys
from datetime import datetime

class Device(NamedTuple):
    name: str
    vendor_id: int
    product_id: int
    mac_layout: bool = False


devices = [
    Device(
        name="macbook",
        vendor_id=1452,
        product_id=832,
        mac_layout=True,
    ),
    Device(
        name="g.skill",
        vendor_id=10458,
        product_id=5381,
    ),
    Device(
        name="microsoft",
        vendor_id=1118,
        product_id=1957,
    ),
    Device(
        name="reddragon",
        vendor_id=9610,
        product_id=4102,
    ),
    Device(
        name="telink",
        vendor_id=9354,
        product_id=33639,
    ),
    Device(
        name="fintie",
        vendor_id=1256,
        product_id=28705,
        mac_layout=True,
    ),
]


def generate_device(device: Device) -> Dict[str, Any]:
    device_config = {
        "identifiers": {
            "is_keyboard": True,
            "is_pointing_device": False,
            "product_id": device.product_id,
            "vendor_id": device.vendor_id,
        },
        "disable_built_in_keyboard_if_exists": False,
        "ignore": False,
        "manipulate_caps_lock_led": False,
        "fn_function_keys": [
            {"from": {"key_code": f"f{x}"}, "to": {"key_code": f"f{x}"}}
            for x in range(1, 13)
        ]
    }

    if not device.mac_layout:
        device_config["simple_modifications"] = [
            {"from": {"key_code": "left_command"}, "to": {"key_code": "left_option"}},
            {"from": {"key_code": "left_option"},  "to": {"key_code": "left_command"}},
            {"from": {"key_code": "application"},  "to": {"key_code": "right_option"}},
            {"from": {"key_code": "right_option"}, "to": {"key_code": "right_command"}},
        ]

    return device_config



def main():
    config_file = sys.argv[1]

    config = {
        "global": {
            "check_for_updates_on_startup": True,
            "show_in_menu_bar": False,
            "show_profile_name_in_menu_bar": False,
        },

        "profiles": [{
            "name": "default profile",
            "selected": True,
            "parameters": {
                "delay_milliseconds_before_open_device": 1000,
            },
            "simple_modifications": [
                {
                    "from": {
                        "key_code": "caps_lock"
                        },
                    "to": [
                        {
                            "key_code": "escape"
                            }
                        ]
                    }
                ],
            "virtual_hid_keyboard": {"country_code": 0, "mouse_key_xy_scale": 100}, 

            "complex_modifications": {
                "parameters": {
                    "basic.simultaneous_threshold_milliseconds": 50,
                    "basic.to_delayed_action_delay_milliseconds": 500,
                    "basic.to_if_alone_timeout_milliseconds": 1000,
                    "basic.to_if_held_down_threshold_milliseconds": 500,
                    "mouse_motion_to_scroll.speed": 100
                },
                "rules": [{
                    "manipulators": [{
                        "description": "change right command to command+control+option+shift",
                        "from": {"key_code": "right_command", "modifiers": {"optional": ["any"]}},
                        "to": [
                            {"key_code": "left_shift", "modifiers": ["left_command", "left_control", "left_option"]},
                        ],
                        "type": "basic",
                    }]
                }, {
                    "manipulators": [{
                        "description": "change right option to command+control+option",
                        "from": {"key_code": "right_option", "modifiers": {"optional": ["any"]}},
                        "to": [{"key_code": "left_shift", "modifiers": ["left_command", "left_control"]}],
                        "type": "basic"
                    }]
                }]
            },

            "devices": [generate_device(d) for d in devices]
        }]

    }

    with open(config_file, "w") as f:
        json.dump(config, f, sort_keys=True, indent=4, separators=(",", ": "))


if __name__ == "__main__":
    main()

