// ParticleField.swift
// A lightweight GPU-accelerated particle field using SwiftUI's Canvas.
// The particle count scales with progress for a more dramatic effect.

import SwiftUI
import os

struct ParticleField: View {
    var progress: Double
    private let logger = Logger(subsystem: "com.universalmanifestor.app", category: "ParticleField")
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas(opaque: false, colorMode: .extendedLinear) { context, size in
                guard size.width > 0 && size.height > 0 else { return }
                
                let t = timeline.date.timeIntervalSinceReferenceDate
                let maxParticles = min(1000, Int(150 + progress * 850))
                let baseRadius = 0.6 + progress * 1.8
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                
                for i in 0..<maxParticles {
                    let seed = Double(i) * 12.9898
                    let angle = sin(seed * 2.0 + t * 0.6) * .pi
                    let radius = (0.15 + 0.8 * abs(sin(seed + t * 0.25))) * min(size.width, size.height) * 0.5
                    let x = center.x + CGFloat(cos(angle)) * CGFloat(radius)
                    let y = center.y + CGFloat(sin(angle)) * CGFloat(radius)
                    
                    let hue = (seed * 0.12345).truncatingRemainder(dividingBy: 1.0)
                    let alpha = 0.35 + 0.5 * progress
                    let color = Color(hue: hue, saturation: 0.7, brightness: 1.0, opacity: alpha)
                    
                    let r = max(0.6, baseRadius + 0.9 * sin(seed + t))
                    let rect = CGRect(x: x, y: y, width: r, height: r)
                    let path = Path(ellipseIn: rect)
                    context.fill(path, with: .color(color))
                }
                
                let glowSize = min(size.width, size.height) * (0.25 + 0.55 * progress)
                let glowRect = CGRect(x: center.x - glowSize/2, y: center.y - glowSize/2, width: glowSize, height: glowSize)
                let glow = Path(ellipseIn: glowRect)
                context.fill(glow, with: .radialGradient(
                    .init(colors: [Color.accentColor.opacity(0.35), .clear]),
                    center: .init(x: center.x, y: center.y),
                    startRadius: 0,
                    endRadius: glowSize/2
                ))
            }
        }
        .background(.ultraThinMaterial)
        .onDisappear {
            logger.debug("ParticleField disappeared")
        }
    }
}
