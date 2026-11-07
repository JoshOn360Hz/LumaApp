# Luma

Luma is a small macOS menu bar app for the illuminated Apple logo on supported MacBook Pro models.

## What it does

- Turns logo illumination on or off from the menu bar.
- Can launch automatically when you log in.
- Lets you remove its background helper from the app.

## How it works

Luma uses a background helper to read and change the system's logo illumination setting. macOS asks for administrator approval before the helper can run.

**On** removes Luma's override and returns the logo to Apple's automatic behaviour. **Off** sets the logo illumination override to zero. The logo's brightness is managed by macOS, so Luma does not offer a separate brightness slider.

## Getting started

1. Drag **Luma.app** into **Applications** and open it.
2. Click the Luma icon in the menu bar and choose **Enable Luma**.
3. Approve the helper when macOS asks. If approval is pending, allow Luma in **System Settings → General → Login Items & Extensions**.

Luma requires macOS 27.2 or later and a supported PROLED XDR MacBook Pro (`Mac17,10`, `Mac17,11`, `Mac17,12`, or `Mac17,13`). It shows an unsupported message on other Macs.

To uninstall, choose **Remove Luma…** in the menu before moving the app to Trash. Turn illumination on first if you want to leave the logo in Apple's automatic mode.
