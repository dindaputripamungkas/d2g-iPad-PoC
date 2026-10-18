# Design2GarmentCode

This is the iPad client for the local pattern-generation server in
[`server/`](../../server). It has no label picker: the photo is classified on
the iPad using Apple Foundation Models, then the app sends the image and the
generated constrained labels to `POST /v1/patterns`.

## Requirements

- An Apple-Intelligence-capable iPad running iPadOS 27 or later, with Apple
  Intelligence enabled and its on-device model ready.
- Xcode 27 or later. This Mac currently has Command Line Tools only, so the
  project cannot be compiled or signed here until full Xcode is installed.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) to create the `.xcodeproj`
  from `project.yml`.
- The Python server started on the Mac and both devices on the same Wi-Fi.

## Run it

1. Start the Python server at the repository root:

   ```bash
   conda run -n garmentcode uvicorn server.pattern_api:app --host 0.0.0.0 --port 8000
   ```

2. Find the Mac’s Wi-Fi IP address, for example `192.168.1.42`.
3. From this directory, run `xcodegen generate`, then open
   `Design2GarmentCode.xcodeproj` in Xcode.
4. Choose your physical iPad as the run destination, set a Development Team in
   Signing & Capabilities, and run the app.
5. In the app, set the server URL to `http://<MAC-WIFI-IP>:8000`, choose a
   garment photo, and tap **Create pattern**.

The iPad automatically displays the exact labels it selected so you can audit
the Foundation Model’s decision, but there is intentionally no label-entry UI.

## Current scope

The constrained automatic classification covers garment family, waistband,
bottom family, connected-dress state, front/back neckline, and sleeveless
state. It is enough to eliminate manual input and exercise the complete
iPad-photo-to-pattern flow. It does not yet classify every one of the server's
fine-grained garment fields; extend `GarmentLabels.swift` with more constrained
enums after evaluating this first flow.

`NSAllowsLocalNetworking` is deliberately enabled for development over the
local HTTP server. A production app needs HTTPS, authentication, rate limits,
and private artifact storage.
