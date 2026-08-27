# Introduction
FOXTracker is a facial head tracker for gaming usage. Perform as TrackIR or [Opentrack](https://github.com/opentrack/opentrack) (pointtracker) as track camera controller for Flight Simulation Games like DCS.

## Build
The project builds with [xmake](https://xmake.io). Dependencies are downloaded from [xrepo](https://xrepo.xmake.io); the three git submodules (PS3EYEDriver, QJoysticks, UGlobalHotkey) are wrapped as local xmake packages under `packages/`.

```bash
# first time only: fetch the submodules (PS3 Eye is optional)
git submodule update --init

# configure + build (Qt6, OpenCV, dlib, onnxruntime, ... are fetched automatically)
xmake f -m release
xmake build -m release
```

Use `-m debug` for a debug build. The Qt6 SDK is downloaded via aqt and OpenCV / Ceres / dlib are built from source, so the first build takes a while.

`xmake run` launches the app from the build directory; runtime assets (`assets/`) and `qt.conf` are copied next to the executable automatically. The PS3 Eye submodule is optional — without it a header-only stub is used and the camera is simply unavailable.

## Usage
This program is still under development, not stable yet. **I will never collect any user data from your camera.**


This program supports control games directly or uses Opentrack as backend. For now, the spline function is in development, so use Opentrack is a good idea. If you are using this program individually, please modify the config in the UI or assets/config.yaml.

Just turn your opentrack input to UDP and open FlightAgentX.exe. Everything works fine.

Also, you may use [dcs.ini](https://github.com/xuhao1/FOXTracker/blob/master/docs/dcs.ini) here.

## Future Plan (Maybe in a year)
1. Try to reinforce the robust of the tracker.
2. Will add spline function.

## LICENSE
LGPL

## Third-party Libraries

[OpenCV](https://opencv.org/)

[dlib](http://dlib.net/)

[UGlobalHotkey](https://github.com/falceeffect/UGlobalHotkey)

[yaml-cpp](https://github.com/jbeder/yaml-cpp)

[Eigen](http://eigen.tuxfamily.org/index.php?title=Main_Page)

[ONNX-Runtime](https://github.com/microsoft/onnxruntime)

[FSA-Net](https://github.com/shamangary/FSA-Net) LICENSE: Apache 2.0 https://github.com/shamangary/FSA-Net/blob/master/LICENSE

[OpenSeeFace](https://github.com/emilianavt/OpenSeeFace) Thanks @emilianavt 's network!

[aitracker](https://github.com/AIRLegend/aitrack)
