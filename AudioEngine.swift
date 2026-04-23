// AudioEngine.swift
// UniversalManifestor
//
// Runtime-synthesized ambient drone and chime effects using AVAudioEngine.
// No external audio files — all audio generated programmatically.
// Cross-platform: iOS 16+ and macOS 13+.

import AVFoundation

final class AudioEngine {

    static let shared = AudioEngine()

    // MARK: - Audio graph nodes

    private let engine = AVAudioEngine()
    private var droneSourceNode: AVAudioSourceNode?
    private var chimeSourceNode: AVAudioSourceNode?
    private let droneMixer = AVAudioMixerNode()
    private let chimeMixer = AVAudioMixerNode()

    // MARK: - Drone harmonics

    private struct Harmonic {
        let frequency: Double
        let amplitude: Float
        let activationProgress: Float
        let triangleBlend: Float   // 0 = pure sine, 1 = pure triangle
    }

    private let harmonics: [Harmonic] = [
        Harmonic(frequency: 136.1,   amplitude: 0.30, activationProgress: 0.00, triangleBlend: 0.0),
        Harmonic(frequency: 272.2,   amplitude: 0.15, activationProgress: 0.00, triangleBlend: 0.0),
        Harmonic(frequency: 408.3,   amplitude: 0.09, activationProgress: 0.15, triangleBlend: 0.3),
        Harmonic(frequency: 544.4,   amplitude: 0.06, activationProgress: 0.30, triangleBlend: 0.3),
        Harmonic(frequency: 68.05,   amplitude: 0.12, activationProgress: 0.45, triangleBlend: 0.0),
        Harmonic(frequency: 170.125, amplitude: 0.08, activationProgress: 0.60, triangleBlend: 0.2),
        Harmonic(frequency: 204.15,  amplitude: 0.06, activationProgress: 0.75, triangleBlend: 0.2),
        Harmonic(frequency: 816.6,   amplitude: 0.03, activationProgress: 0.90, triangleBlend: 0.0),
    ]

    // Phase accumulators: pairs of [left, right] for each harmonic
    private var dronePhases: [Double] = []

    // MARK: - Chime partials

    private struct ChimePartial {
        let frequencyRatio: Double
        let amplitude: Float
    }

    private let startChimePartials: [ChimePartial] = [
        ChimePartial(frequencyRatio: 1.0,  amplitude: 0.40),
        ChimePartial(frequencyRatio: 2.0,  amplitude: 0.20),
        ChimePartial(frequencyRatio: 1.5,  amplitude: 0.15),
        ChimePartial(frequencyRatio: 3.0,  amplitude: 0.08),
    ]
    private let startChimeBaseFreq: Double = 1046.5
    private let startChimeDecay: Float = 0.99975

    private let completionChimePartials: [ChimePartial] = [
        ChimePartial(frequencyRatio: 1.0,   amplitude: 0.35),
        ChimePartial(frequencyRatio: 2.0,   amplitude: 0.22),
        ChimePartial(frequencyRatio: 2.76,  amplitude: 0.15),
        ChimePartial(frequencyRatio: 3.0,   amplitude: 0.12),
        ChimePartial(frequencyRatio: 4.07,  amplitude: 0.09),
        ChimePartial(frequencyRatio: 5.2,   amplitude: 0.05),
    ]
    private let completionChimeBaseFreq: Double = 523.25
    private let completionChimeDecay: Float = 0.99995

    private var chimePhases: [Double] = Array(repeating: 0, count: 12)
    private var chimeAmplitude: Float = 0
    private var chimeDecayRate: Float = 1.0
    private var activeChimePartials: [ChimePartial] = []
    private var activeChimeBaseFreq: Double = 0
    private var chimeActive: Bool = false

    // MARK: - Cross-thread state (simple types — hardware-atomic on ARM64/x86_64)

    private var currentProgress: Float = 0
    private var droneAmplitude: Float = 0
    private var targetDroneAmplitude: Float = 0
    private var sampleRate: Double = 44100

    // Amplitude ramp coefficient — computed once at setup
    private var rampCoeff: Float = 0.0005

    // MARK: - Graph state

    private var isGraphSetup = false
    private var isPlaying = false

    // MARK: - Init

    private init() {
        dronePhases = Array(repeating: 0, count: harmonics.count * 2)
    }

    // MARK: - Audio session (iOS)

    private func configureAudioSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("AudioEngine: Failed to configure audio session: \(error)")
        }
        #endif
    }

    private func deactivateAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("AudioEngine: Failed to deactivate audio session: \(error)")
        }
        #endif
    }

    // MARK: - Graph setup

    private func setupGraph() {
        guard !isGraphSetup else { return }

        sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        if sampleRate == 0 { sampleRate = 44100 }

        // ~50ms ramp time
        rampCoeff = 1.0 / Float(sampleRate * 0.05)

        let stereoFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 2,
            interleaved: false
        )!

        droneSourceNode = AVAudioSourceNode(format: stereoFormat) { [unowned self] isSilence, _, frameCount, audioBufferList in
            self.renderDrone(isSilence: isSilence, frameCount: frameCount, audioBufferList: audioBufferList)
        }

        chimeSourceNode = AVAudioSourceNode(format: stereoFormat) { [unowned self] isSilence, _, frameCount, audioBufferList in
            self.renderChime(isSilence: isSilence, frameCount: frameCount, audioBufferList: audioBufferList)
        }

        engine.attach(droneSourceNode!)
        engine.attach(chimeSourceNode!)
        engine.attach(droneMixer)
        engine.attach(chimeMixer)

        engine.connect(droneSourceNode!, to: droneMixer, format: stereoFormat)
        engine.connect(chimeSourceNode!, to: chimeMixer, format: stereoFormat)
        engine.connect(droneMixer, to: engine.mainMixerNode, format: stereoFormat)
        engine.connect(chimeMixer, to: engine.mainMixerNode, format: stereoFormat)

        isGraphSetup = true
    }

    // MARK: - Drone render

    private func renderDrone(
        isSilence: UnsafeMutablePointer<ObjCBool>,
        frameCount: AVAudioFrameCount,
        audioBufferList: UnsafeMutablePointer<AudioBufferList>
    ) -> OSStatus {
        let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
        guard abl.count >= 2 else { return noErr }

        let leftBuf = abl[0].mData!.assumingMemoryBound(to: Float.self)
        let rightBuf = abl[1].mData!.assumingMemoryBound(to: Float.self)

        let progress = currentProgress
        let twoPi = 2.0 * Double.pi

        for frame in 0..<Int(frameCount) {
            // Ramp amplitude toward target
            let diff = targetDroneAmplitude - droneAmplitude
            droneAmplitude += diff * rampCoeff

            var sampleL: Float = 0
            var sampleR: Float = 0

            for i in 0..<harmonics.count {
                let h = harmonics[i]

                // Skip inactive harmonics
                guard progress >= h.activationProgress else { continue }

                // Smooth activation over 0.1 progress range
                let activation = min(1.0, (progress - h.activationProgress) / 0.1)
                let amp = h.amplitude * activation

                let phaseL = dronePhases[i * 2]
                let phaseR = dronePhases[i * 2 + 1]

                // Sine + optional triangle blend
                let sineL = Float(sin(phaseL))
                let sineR = Float(sin(phaseR))

                if h.triangleBlend > 0 {
                    let triL = triangleWave(phaseL)
                    let triR = triangleWave(phaseR)
                    let blend = h.triangleBlend
                    sampleL += amp * (sineL * (1 - blend) + triL * blend)
                    sampleR += amp * (sineR * (1 - blend) + triR * blend)
                } else {
                    sampleL += amp * sineL
                    sampleR += amp * sineR
                }

                // Advance phases — right channel slightly detuned for stereo width
                let detuneHz = Double(progress) * 0.5
                let incL = h.frequency / sampleRate * twoPi
                let incR = (h.frequency + detuneHz) / sampleRate * twoPi

                dronePhases[i * 2]     += incL
                dronePhases[i * 2 + 1] += incR

                // Wrap phases to avoid precision loss over long sessions
                if dronePhases[i * 2]     > twoPi { dronePhases[i * 2]     -= twoPi }
                if dronePhases[i * 2 + 1] > twoPi { dronePhases[i * 2 + 1] -= twoPi }
            }

            leftBuf[frame]  = sampleL * droneAmplitude
            rightBuf[frame] = sampleR * droneAmplitude
        }

        isSilence.pointee = ObjCBool(droneAmplitude < 0.0001 && targetDroneAmplitude < 0.0001)
        return noErr
    }

    // Branch-free triangle wave from phase in [0, 2π)
    private func triangleWave(_ phase: Double) -> Float {
        let t = phase / (2.0 * Double.pi)
        return Float(4.0 * abs(t - floor(t + 0.5)) - 1.0)
    }

    // MARK: - Chime render

    private func renderChime(
        isSilence: UnsafeMutablePointer<ObjCBool>,
        frameCount: AVAudioFrameCount,
        audioBufferList: UnsafeMutablePointer<AudioBufferList>
    ) -> OSStatus {
        let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
        guard abl.count >= 2 else { return noErr }

        let leftBuf = abl[0].mData!.assumingMemoryBound(to: Float.self)
        let rightBuf = abl[1].mData!.assumingMemoryBound(to: Float.self)

        guard chimeActive else {
            // Fill with silence
            for frame in 0..<Int(frameCount) {
                leftBuf[frame] = 0
                rightBuf[frame] = 0
            }
            isSilence.pointee = ObjCBool(true)
            return noErr
        }

        let twoPi = 2.0 * Double.pi
        let partials = activeChimePartials
        let baseFreq = activeChimeBaseFreq

        for frame in 0..<Int(frameCount) {
            chimeAmplitude *= chimeDecayRate

            if chimeAmplitude < 0.0001 {
                chimeAmplitude = 0
                chimeActive = false
                leftBuf[frame] = 0
                rightBuf[frame] = 0
                // Fill remaining frames with silence
                for remaining in (frame + 1)..<Int(frameCount) {
                    leftBuf[remaining] = 0
                    rightBuf[remaining] = 0
                }
                break
            }

            var sample: Float = 0
            for (j, partial) in partials.enumerated() {
                let phase = chimePhases[j]
                sample += partial.amplitude * Float(sin(phase))

                let freq = baseFreq * partial.frequencyRatio
                chimePhases[j] += freq / sampleRate * twoPi
                if chimePhases[j] > twoPi { chimePhases[j] -= twoPi }
            }

            let out = sample * chimeAmplitude
            leftBuf[frame]  = out
            rightBuf[frame] = out
        }

        isSilence.pointee = ObjCBool(!chimeActive)
        return noErr
    }

    // MARK: - Chime trigger

    private func triggerChime(partials: [ChimePartial], baseFreq: Double, decay: Float) {
        // Reset phases
        for i in 0..<chimePhases.count { chimePhases[i] = 0 }
        activeChimePartials = partials
        activeChimeBaseFreq = baseFreq
        chimeDecayRate = decay
        chimeAmplitude = 1.0
        chimeActive = true
    }

    // MARK: - Public API

    func start() {
        configureAudioSession()
        setupGraph()

        // Reset drone state
        for i in 0..<dronePhases.count { dronePhases[i] = 0 }
        droneAmplitude = 0
        currentProgress = 0
        targetDroneAmplitude = 0.3

        do {
            try engine.start()
        } catch {
            print("AudioEngine: Failed to start engine: \(error)")
            return
        }

        isPlaying = true

        // Play start chime
        triggerChime(partials: startChimePartials, baseFreq: startChimeBaseFreq, decay: startChimeDecay)
    }

    func pause() {
        targetDroneAmplitude = 0
        isPlaying = false
    }

    func resume() {
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("AudioEngine: Failed to resume engine: \(error)")
                return
            }
        }
        targetDroneAmplitude = 0.3 + currentProgress * 0.3
        isPlaying = true
    }

    func updateProgress(_ p: Float) {
        currentProgress = p
        if isPlaying {
            targetDroneAmplitude = 0.3 + p * 0.3
        }
    }

    func complete() {
        targetDroneAmplitude = 0
        isPlaying = false

        // Play completion chime
        triggerChime(partials: completionChimePartials, baseFreq: completionChimeBaseFreq, decay: completionChimeDecay)

        // Stop engine after chime finishes
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            guard let self, !self.isPlaying else { return }
            self.engine.stop()
            self.deactivateAudioSession()
        }
    }

    func stop() {
        targetDroneAmplitude = 0
        chimeActive = false
        chimeAmplitude = 0
        isPlaying = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self, !self.isPlaying else { return }
            self.engine.stop()
            self.deactivateAudioSession()
            // Reset phases
            for i in 0..<self.dronePhases.count { self.dronePhases[i] = 0 }
        }
    }
}
