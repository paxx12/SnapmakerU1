from __future__ import annotations
from typing import TYPE_CHECKING, Dict, Any

if TYPE_CHECKING:
    from confighelper import ConfigHelper
    from ..common import WebRequest

class Timelapse:
    """Stub timelapse component for Mainsail compatibility.

    Provides empty API responses to prevent UI errors.
    Actual timelapse functionality is handled by OrcaSlicer.
    """

    def __init__(self, confighelper: ConfigHelper) -> None:
        self.confighelper = confighelper
        self.server = confighelper.get_server()

        # Register timelapse directory with file manager
        file_manager = self.server.lookup_component("file_manager")
        camera_path = file_manager.datapath.joinpath("camera")
        file_manager.register_directory("timelapse",
                                        str(camera_path),
                                        full_access=True)

        # Register API endpoints that Mainsail expects
        self.server.register_endpoint(
            "/machine/timelapse/settings",
            ["GET", "POST"],
            self._handle_settings
        )
        self.server.register_endpoint(
            "/machine/timelapse/lastframeinfo",
            ["GET"],
            self._handle_lastframeinfo
        )
        self.server.register_endpoint(
            "/machine/timelapse/render",
            ["POST"],
            self._handle_render
        )

    async def _handle_settings(self, web_request: WebRequest) -> Dict[str, Any]:
        """Return stub timelapse settings."""
        return {
            "enabled": False,
            "autorender": False,
            "mode": "layermacro",
            "camera": "",
            "snapshoturl": "",
            "stream_delay_compensation": 0.05,
            "gcode_verbose": False,
            "parkhead": False,
            "parkpos": "back_left",
            "park_custom_pos_x": 0.0,
            "park_custom_pos_y": 0.0,
            "park_custom_pos_dz": 0.0,
            "park_travel_speed": 100,
            "park_retract_speed": 15,
            "park_extrude_speed": 15,
            "park_retract_distance": 1.0,
            "park_extrude_distance": 1.0,
            "hyperlapse_cycle": 30,
            "fw_retract": False,
            "constant_rate_factor": 23,
            "output_framerate": 30,
            "pixelformat": "yuv420p",
            "extraoutputparams": "",
            "variable_fps": False,
            "targetlength": 10,
            "variable_fps_min": 5,
            "variable_fps_max": 60,
            "duplicatelastframe": 0,
            "previewimage": True,
            "saveframes": False
        }

    async def _handle_lastframeinfo(self, web_request: WebRequest) -> Dict[str, Any]:
        """Return stub last frame info."""
        return {
            "lastframefile": "",
            "count": 0
        }

    async def _handle_render(self, web_request: WebRequest) -> Dict[str, Any]:
        """Return stub render response."""
        return {
            "status": "not_available",
            "msg": "Timelapse rendering not available. Use OrcaSlicer for timelapse."
        }

def load_component(config: ConfigHelper) -> Timelapse:
    return Timelapse(config)
