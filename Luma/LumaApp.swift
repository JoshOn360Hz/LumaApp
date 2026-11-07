import AppKit
import SwiftUI

@main
struct LumaApp: App {
    @StateObject private var service = IlluminationService()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(service: service)
        } label: {
            ZStack {
                Image(nsImage: menuBarImage)
                if service.state == .off {
                    Image(systemName: "slash")
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .frame(width: 18, height: 18)
            .accessibilityLabel("Luma: \(service.state.subtitle)")
        }
        .menuBarExtraStyle(.window)
    }

    private var menuBarImage: NSImage {
        let size = NSSize(width: 18, height: 18)
        guard let source = NSImage(named: "LumaMenuBar"),
              let bitmap = source.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            let fallback = NSImage(systemSymbolName: "sun.max", accessibilityDescription: nil)
                ?? NSImage(size: size)
            fallback.size = size
            fallback.isTemplate = true
            return fallback
        }

        // The supplied artwork has transparent margins. Crop those margins so
        // the visible mark fills a normal 18-point menu bar image.
        let insetX = CGFloat(bitmap.width) * 90 / 512
        let insetY = CGFloat(bitmap.height) * 90 / 512
        let crop = CGRect(
            x: insetX,
            y: insetY,
            width: CGFloat(bitmap.width) - 2 * insetX,
            height: CGFloat(bitmap.height) - 2 * insetY
        ).integral
        guard let cropped = bitmap.cropping(to: crop) else {
            source.size = size
            source.isTemplate = true
            return source
        }
        let image = NSImage(cgImage: cropped, size: size)
        image.isTemplate = true
        return image
    }
}
