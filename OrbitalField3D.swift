// OrbitalField3D.swift
// Cross-platform 3D scene with a glowing core, orbiting beads, and additive particles.
// Progress (0...1) increases intensity, speed, and glow for a more dramatic effect.

import SwiftUI
import SceneKit
import QuartzCore
import os

#if os(iOS)
import UIKit
private typealias NativeColor = UIColor
private extension UIColor {
    convenience init(calibratedHue h: CGFloat, saturation s: CGFloat, brightness b: CGFloat, alpha a: CGFloat) {
        self.init(hue: h, saturation: s, brightness: b, alpha: a)
    }
    convenience init(calibratedWhite w: CGFloat, alpha a: CGFloat) {
        self.init(white: w, alpha: a)
    }
}
#else
import AppKit
private typealias NativeColor = NSColor
#endif

#if os(iOS)
struct OrbitalField3D: UIViewRepresentable {
    var progress: Double
    func makeUIView(context: Context) -> SCNView { buildScene(coordinator: context.coordinator) }
    func updateUIView(_ view: SCNView, context: Context) { apply(progress: progress, coordinator: context.coordinator) }
    func makeCoordinator() -> Coordinator { Coordinator() }
    func dismantleUIView(_ view: SCNView, coordinator: Coordinator) { coordinator.cleanup() }
}
#else
struct OrbitalField3D: NSViewRepresentable {
    var progress: Double
    func makeNSView(context: Context) -> SCNView { buildScene(coordinator: context.coordinator) }
    func updateNSView(_ view: SCNView, context: Context) { apply(progress: progress, coordinator: context.coordinator) }
    func makeCoordinator() -> Coordinator { Coordinator() }
    func dismantleNSView(_ view: SCNView, coordinator: Coordinator) { coordinator.cleanup() }
}
#endif

extension OrbitalField3D {
    private var logger: Logger { Logger(subsystem: "com.universalmanifestor.app", category: "OrbitalField3D") }
    private static let logger = Logger(subsystem: "com.universalmanifestor.app", category: "OrbitalField3D")
    
    func buildScene(coordinator: Coordinator) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .black
        scnView.antialiasingMode = .multisampling4X
        scnView.allowsCameraControl = false

        let scene = SCNScene()
        scene.background.contents = NativeColor.black
        scnView.scene = scene

        // Camera
        let camera = SCNCamera()
        camera.zFar = 1000
        camera.wantsHDR = true
        camera.bloomIntensity = 2.0
        camera.bloomThreshold = 0.28
        camera.bloomBlurRadius = 14.0
        camera.wantsExposureAdaptation = false
        camera.exposureOffset = 0.4
        camera.contrast = 0.12
        camera.saturation = 1.25
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 12)
        scene.rootNode.addChildNode(cameraNode)

        // Central sphere
        let core = SCNSphere(radius: 1.6)
        core.segmentCount = 96
        let coreMat = SCNMaterial()
        coreMat.lightingModel = .physicallyBased
        coreMat.diffuse.contents = NativeColor(calibratedHue: 0.65, saturation: 0.5, brightness: 0.12, alpha: 1.0)
        coreMat.emission.contents = NativeColor.black
        coreMat.metalness.contents = 0.2
        coreMat.roughness.contents = 0.15
        
        let surfaceShader = """
#pragma arguments
float u_time;
float u_progress;
#pragma body
float p2     = u_progress * u_progress;
float ndv    = clamp(dot(_surface.normal, _surface.view), 0.0, 1.0);
float fres   = pow(1.0 - ndv, max(0.5, 1.8 - 1.3 * u_progress));
float fscale = 1.0 + 4.0 * p2;
float tscale = 1.0 + 3.0 * u_progress;
float wave1  = 0.5 + 0.5 * sin(_surface.position.y * 5.5 * fscale + u_time * 1.9 * tscale);
float wave2  = 0.5 + 0.5 * sin(_surface.position.x * 4.3 * fscale - u_time * 1.5 * tscale);
float wave3  = 0.5 + 0.5 * sin(_surface.position.z * 6.2 * fscale + u_time * 2.4 * tscale);
float membrane = wave1 * 0.40 + wave2 * 0.35 + wave3 * 0.25;
float pulse  = 0.5 + 0.5 * sin(u_time * (2.7 + 5.5 * u_progress) + u_progress * 6.28318);
float breathe = 0.5 + 0.5 * sin(u_time * 0.62);
float t_pal  = fract(u_time * (0.07 + 0.14 * u_progress));
float3 palA  = float3(0.55, 0.40, 0.65);
float3 palB  = float3(0.45, 0.35, 0.45);
float3 palC  = float3(0.90, 0.70, 1.10);
float3 palD  = float3(0.00, 0.25, 0.65);
float3 morphCol = palA + palB * cos(6.28318 * (palC * t_pal + palD));
morphCol += float3(0.75, 0.65, 1.0) * p2 * fres * 2.5;
float intensity  = 0.18 + 2.6 * p2;
float base_glow  = clamp(fres * 2.6 + membrane * (0.70 + 2.5 * u_progress), 0.0, 6.0);
float glow = base_glow * (0.55 + 0.60 * pulse) * (0.85 + 0.18 * breathe) * intensity;
_surface.emission.rgb += glow * morphCol;
"""
        coreMat.shaderModifiers = [.surface: surfaceShader]
        coreMat.setValue(0.0, forKey: "u_time")
        coreMat.setValue(progress, forKey: "u_progress")
        core.materials = [coreMat]
        let coreNode = SCNNode(geometry: core)
        scene.rootNode.addChildNode(coreNode)

        let pulseUp = SCNAction.scale(to: 1.11, duration: 2.0)
        pulseUp.timingMode = .easeInEaseOut
        let pulseDown = SCNAction.scale(to: 1.0, duration: 2.0)
        pulseDown.timingMode = .easeInEaseOut
        coreNode.runAction(SCNAction.repeatForever(SCNAction.sequence([pulseUp, pulseDown])), forKey: "membranePulse")

        // Rings
        func makeRing(ringR: CGFloat, pipeR: CGFloat, hue: CGFloat) -> (SCNNode, SCNMaterial) {
            let geo = SCNTorus(ringRadius: ringR, pipeRadius: pipeR)
            let mat = SCNMaterial()
            mat.lightingModel = .physicallyBased
            mat.emission.contents = NativeColor(calibratedHue: hue, saturation: 0.85, brightness: 0.40, alpha: 1.0)
            mat.diffuse.contents = NativeColor.white.withAlphaComponent(0.04)
            mat.metalness.contents = 0.05
            mat.roughness.contents = 0.04
            geo.materials = [mat]
            return (SCNNode(geometry: geo), mat)
        }
        let (ringNodeA, ringMatA) = makeRing(ringR: 4.4, pipeR: 0.045, hue: 0.76)
        let (ringNodeB, ringMatB) = makeRing(ringR: 3.6, pipeR: 0.038, hue: 0.62)
        let (ringNodeC, ringMatC) = makeRing(ringR: 2.8, pipeR: 0.032, hue: 0.52)
        ringNodeA.eulerAngles = SCNVector3(0.5, 0.0, 0.2)
        ringNodeB.eulerAngles = SCNVector3(-0.3, 0.6, 0.0)
        ringNodeC.eulerAngles = SCNVector3(0.1, -0.4, 0.7)
        [ringNodeA, ringNodeB, ringNodeC].forEach { scene.rootNode.addChildNode($0) }

        // Particles
        let ps = SCNParticleSystem()
        ps.loops = true
        ps.birthRate = 500
        ps.particleLifeSpan = 3.5
        ps.particleLifeSpanVariation = 1.5
        ps.particleSize = 0.05
        ps.particleSizeVariation = 0.03
        ps.particleVelocity = 1.5
        ps.particleVelocityVariation = 1.2
        ps.particleColor = NativeColor(calibratedHue: 0.72, saturation: 0.70, brightness: 1.0, alpha: 1.0)
        ps.particleColorVariation = SCNVector4(0.22, 0.40, 0.30, 0.0)
        ps.blendMode = .additive
        ps.emitterShape = SCNSphere(radius: 2.0)
        ps.spreadingAngle = 30
        ps.isAffectedByGravity = false
        let emitter = SCNNode()
        emitter.addParticleSystem(ps)
        scene.rootNode.addChildNode(emitter)

        let sparkle = SCNParticleSystem()
        sparkle.loops = true
        sparkle.birthRate = 55
        sparkle.particleLifeSpan = 2.2
        sparkle.particleLifeSpanVariation = 1.2
        sparkle.particleSize = 0.11
        sparkle.particleSizeVariation = 0.07
        sparkle.particleVelocity = 0.7
        sparkle.particleVelocityVariation = 0.5
        sparkle.particleColor = NativeColor(calibratedWhite: 1.0, alpha: 0.95)
        sparkle.particleColorVariation = SCNVector4(0.12, 0.0, 0.18, 0.28)
        sparkle.blendMode = .additive
        sparkle.emitterShape = SCNSphere(radius: 2.7)
        sparkle.spreadingAngle = 180
        sparkle.isAffectedByGravity = false
        let sparkleNode = SCNNode()
        sparkleNode.addParticleSystem(sparkle)
        scene.rootNode.addChildNode(sparkleNode)

        let nebula = SCNParticleSystem()
        nebula.loops = true
        nebula.birthRate = 160
        nebula.particleLifeSpan = 8.0
        nebula.particleLifeSpanVariation = 3.5
        nebula.particleSize = 0.04
        nebula.particleSizeVariation = 0.025
        nebula.particleVelocity = 0.45
        nebula.particleVelocityVariation = 0.45
        nebula.particleColor = NativeColor(calibratedHue: 0.76, saturation: 0.55, brightness: 0.9, alpha: 1.0)
        nebula.particleColorVariation = SCNVector4(0.14, 0.22, 0.22, 0.0)
        nebula.blendMode = .additive
        nebula.emitterShape = SCNSphere(radius: 12.0)
        nebula.spreadingAngle = 8
        nebula.isAffectedByGravity = false
        let nebulaNode = SCNNode()
        nebulaNode.addParticleSystem(nebula)
        scene.rootNode.addChildNode(nebulaNode)

        // Lights
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.color = NativeColor(white: 0.05, alpha: 1)
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)

        let keyLight = SCNLight()
        keyLight.type = .omni
        keyLight.color = NativeColor(calibratedHue: 0.60, saturation: 0.30, brightness: 1.0, alpha: 1.0)
        keyLight.intensity = 520
        let keyNode = SCNNode()
        keyNode.light = keyLight
        keyNode.position = SCNVector3(6, 5, 9)
        scene.rootNode.addChildNode(keyNode)

        let rimLight = SCNLight()
        rimLight.type = .omni
        rimLight.color = NativeColor(calibratedHue: 0.76, saturation: 0.65, brightness: 0.9, alpha: 1.0)
        rimLight.intensity = 460
        let rimNode = SCNNode()
        rimNode.light = rimLight
        rimNode.position = SCNVector3(-6, -3, -7)
        scene.rootNode.addChildNode(rimNode)

        let fillLight = SCNLight()
        fillLight.type = .omni
        fillLight.color = NativeColor(calibratedHue: 0.52, saturation: 0.50, brightness: 0.8, alpha: 1.0)
        fillLight.intensity = 240
        let fillNode = SCNNode()
        fillNode.light = fillLight
        fillNode.position = SCNVector3(0, -6, 5)
        scene.rootNode.addChildNode(fillNode)

        let wobble = CABasicAnimation(keyPath: "rotation")
        wobble.fromValue = NSValue(scnVector4: SCNVector4(0.3, 1, 0.2, 0))
        wobble.toValue = NSValue(scnVector4: SCNVector4(0.3, 1, 0.2, Float.pi * 2))
        wobble.duration = 26
        wobble.repeatCount = .infinity
        coreNode.addAnimation(wobble, forKey: "wobble")

        coordinator.ringA = ringNodeA
        coordinator.ringB = ringNodeB
        coordinator.ringC = ringNodeC
        coordinator.ringMatA = ringMatA
        coordinator.ringMatB = ringMatB
        coordinator.ringMatC = ringMatC
        coordinator.emitter = ps
        coordinator.sparkle = sparkle
        coordinator.nebula = nebula
        coordinator.coreMaterial = coreMat
        coordinator.coreNode = coreNode
        coordinator.camera = camera

        apply(progress: progress, coordinator: coordinator)

        coordinator.startTime = CFAbsoluteTimeGetCurrent()
        coordinator.timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak coordinator] _ in
            guard let coordinator = coordinator else { return }
            let t = CFAbsoluteTimeGetCurrent() - (coordinator.startTime ?? 0)
            coreMat.setValue(NSNumber(value: t), forKey: "u_time")
        }

        OrbitalField3D.logger.debug("3D scene built")
        return scnView
    }

    final class Coordinator {
        var ringA: SCNNode?
        var ringB: SCNNode?
        var ringC: SCNNode?
        var ringMatA: SCNMaterial?
        var ringMatB: SCNMaterial?
        var ringMatC: SCNMaterial?
        var emitter: SCNParticleSystem?
        var sparkle: SCNParticleSystem?
        var nebula: SCNParticleSystem?
        var coreMaterial: SCNMaterial?
        var coreNode: SCNNode?
        var camera: SCNCamera?
        var timer: Timer?
        var startTime: CFTimeInterval?
        
        func cleanup() {
            timer?.invalidate()
            timer = nil
            ringA?.removeAllActions()
            ringB?.removeAllActions()
            ringC?.removeAllActions()
            coreNode?.removeAllActions()
            ringA = nil
            ringB = nil
            ringC = nil
            ringMatA = nil
            ringMatB = nil
            ringMatC = nil
            emitter = nil
            sparkle = nil
            nebula = nil
            coreMaterial = nil
            coreNode = nil
            camera = nil
            OrbitalField3D.logger.debug("Coordinator cleaned up")
        }
    }

    private func apply(progress p: Double, coordinator c: Coordinator) {
        let q = max(0.0, min(1.0, p))
        let q2 = q * q

        c.emitter?.birthRate = CGFloat(200 + 2200 * q2)
        c.emitter?.particleVelocity = CGFloat(1.2 + 2.2 * q)
        c.emitter?.particleSize = CGFloat(0.04 + 0.10 * q)
        c.sparkle?.birthRate = CGFloat(20 + 200 * q2)
        c.nebula?.birthRate = CGFloat(60 + 380 * q2)

        c.coreMaterial?.setValue(NSNumber(value: q), forKey: "u_progress")

        if let node = c.coreNode {
            let dur = max(0.50, 2.0 - 1.3 * q)
            let minSc = 1.0 + CGFloat(q2) * 0.22
            let maxSc = minSc + 0.09 + CGFloat(q) * 0.10
            node.removeAction(forKey: "membranePulse")
            let up = SCNAction.scale(to: maxSc, duration: dur)
            up.timingMode = .easeInEaseOut
            let down = SCNAction.scale(to: minSc, duration: dur)
            down.timingMode = .easeInEaseOut
            node.runAction(SCNAction.repeatForever(SCNAction.sequence([up, down])),
                           forKey: "membranePulse")
        }

        let rb = 0.35 + 0.95 * q
        let rs = CGFloat(0.85 + 0.15 * q)
        c.ringMatA?.emission.contents = NativeColor(calibratedHue: 0.76, saturation: rs, brightness: rb, alpha: 1.0)
        c.ringMatB?.emission.contents = NativeColor(calibratedHue: 0.62, saturation: rs, brightness: rb, alpha: 1.0)
        c.ringMatC?.emission.contents = NativeColor(calibratedHue: 0.52, saturation: rs, brightness: rb, alpha: 1.0)

        func runSpin(_ node: SCNNode?, axis: SCNVector3, base: Double, key: String) {
            guard let node else { return }
            node.removeAnimation(forKey: key, blendOutDuration: 0.2)
            let spin = CABasicAnimation(keyPath: "rotation")
            let two = CGFloat(Double.pi * 2)
            spin.fromValue = NSValue(scnVector4: SCNVector4(CGFloat(axis.x), CGFloat(axis.y), CGFloat(axis.z), 0))
            spin.toValue = NSValue(scnVector4: SCNVector4(CGFloat(axis.x), CGFloat(axis.y), CGFloat(axis.z), two))
            spin.duration = max(1.5, base - base * 0.65 * q)
            spin.repeatCount = .infinity
            spin.isRemovedOnCompletion = false
            node.addAnimation(spin, forKey: key)
        }
        runSpin(c.ringA, axis: SCNVector3(0, 1, 0.1), base: 18, key: "spinA")
        runSpin(c.ringB, axis: SCNVector3(0.1, 0, 1), base: 22, key: "spinB")
        runSpin(c.ringC, axis: SCNVector3(1, 0.1, 0), base: 26, key: "spinC")
    }
}
