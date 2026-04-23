// AudioEngine.swift - MINIMAL VERSION for iPad M4 compatibility
import AVFoundation

final class AudioEngine {
    static let shared = AudioEngine()
    
    private let engine = AVAudioEngine()
    private var isGraphSetup = false
    private var isPlaying = false
    private var currentProgress: Float = 0
    
    private init() {}
    
    func setupGraphIfNeeded() throws {
        guard !isGraphSetup else { return }
        
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
        #endif
        
        let mainMixer = engine.mainMixerNode
        mainMixer.outputVolume = 1.0
        isGraphSetup = true
    }
    
    func play() throws {
        try setupGraphIfNeeded()
        guard !isPlaying else { return }
        
        engine.prepare()
        try engine.start()
        isPlaying = true
    }
    
    func stop() {
        if engine.isRunning {
            engine.stop()
        }
        isPlaying = false
    }
    
    func updateProgress(_ progress: Float) {
        currentProgress = progress
    }
    
    func complete() {
        // Simple completion - no audio overload
    }
}
