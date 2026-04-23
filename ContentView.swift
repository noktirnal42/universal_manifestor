// ContentView.swift - Universal Manifestor
import SwiftUI
import Combine

#if os(iOS)
import UIKit
#endif

// MARK: - App Constants
private struct AppConstants {
    static let defaultIterations: Int = 7
    static let secondsPerIteration: Double = 5.0
    static let maxIterations: Int = 20
    static let minIterations: Int = 1
    static let maxIntentionLength: Int = 500
    static let timerInterval: Double = 0.05
}

// MARK: - Color Extensions
private extension Color {
    static let auraViolet = Color(hue: 0.76, saturation: 0.62, brightness: 0.88)
    static let auraBlue = Color(hue: 0.60, saturation: 0.72, brightness: 1.00)
    static let auraTeal = Color(hue: 0.52, saturation: 0.68, brightness: 0.95)
}

// MARK: - Keyboard Dismissal Helper
#if os(iOS)
extension View {
    func hideKeyboard() {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .endEditing(true)
    }
}
#endif

// MARK: - View Model
@MainActor
final class TransmissionViewModel: ObservableObject {
    @Published var intention: String = ""
    @Published private(set) var iterations: Int = AppConstants.defaultIterations
    @Published private(set) var remainingSeconds: Double = 35.0
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var isError: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var progress: Double = 0.0
    
    private let audio = AudioEngine.shared
    private let secondsPerIteration: Double = AppConstants.secondsPerIteration
    private var timerTask: Task<Void, Never>?
    
    var transmissionSeconds: Double {
        Double(max(AppConstants.minIterations, iterations)) * secondsPerIteration
    }
    
    var formattedTime: String {
        let s = Int(remainingSeconds.rounded(.up))
        return String(format: "%d:%02d", s / 60, s % 60)
    }
    
    var canStart: Bool {
        !intention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func setIntention(_ text: String) {
        if text.count <= AppConstants.maxIntentionLength {
            intention = text
        }
    }
    
    func incrementIterations() {
        iterations = min(AppConstants.maxIterations, iterations + 1)
        if !isRunning {
            remainingSeconds = transmissionSeconds
        }
    }
    
    func decrementIterations() {
        iterations = max(AppConstants.minIterations, iterations - 1)
        if !isRunning {
            remainingSeconds = transmissionSeconds
        }
    }
    
    func startTransmission() {
        guard !isRunning else { return }
        
        Task { @MainActor in
            do {
                try audio.setupGraphIfNeeded()
                try audio.play()
                
                isRunning = true
                isError = false
                errorMessage = nil
                
                timerTask = Task { @MainActor in
                    while !Task.isCancelled && self.isRunning {
                        try? await Task.sleep(nanoseconds: UInt64(AppConstants.timerInterval * 1_000_000_000))
                        
                        if Task.isCancelled || !self.isRunning { break }
                        
                        self.remainingSeconds = max(0, self.remainingSeconds - AppConstants.timerInterval)
                        self.progress = min(1.0, max(0.0, 1.0 - (self.remainingSeconds / self.transmissionSeconds)))
                        self.audio.updateProgress(Float(self.progress))
                        
                        if self.remainingSeconds <= 0 {
                            self.completeTransmission()
                        }
                    }
                }
            } catch {
                isError = true
                errorMessage = "Audio initialization failed: \(error.localizedDescription)"
                isRunning = false
            }
        }
    }
    
    func stopTransmission() {
        isRunning = false
        timerTask?.cancel()
        timerTask = nil
        audio.stop()
    }
    
    private func completeTransmission() {
        stopTransmission()
        audio.complete()
        
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        #endif
    }
    
    func reset() {
        stopTransmission()
        remainingSeconds = transmissionSeconds
        intention = ""
        progress = 0.0
        isError = false
        errorMessage = nil
        audio.stop()
    }
    
    func cleanup() {
        stopTransmission()
    }
}

// MARK: - Content View
struct ContentView: View {
    @StateObject private var viewModel = TransmissionViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @FocusState private var isIntentionFocused: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(edges: .horizontal)
            
            ScrollView {
                VStack(spacing: 14) {
                    titleSection
                    intentionSection
                    iterationsSection
                    progressSection
                    controlButtons
                    
                    if viewModel.isError, let message = viewModel.errorMessage {
                        errorSection(message: message)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isIntentionFocused = false
                #if os(iOS)
                hideKeyboard()
                #endif
            }
        }
        .onDisappear { viewModel.cleanup() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Universal Manifestor")
    }
    
    // MARK: - Sections
    private var titleSection: some View {
        VStack(spacing: 5) {
            Text("UNIVERSAL MANIFESTOR")
                .font(.system(size: scaledFont(20), weight: .ultraLight))
                .tracking(7)
                .foregroundStyle(LinearGradient(
                    colors: [.auraViolet, .auraBlue, .auraTeal],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .accessibilityLabel("Universal Manifestor")
            
            Text("for entertainment & mindfulness only")
                .font(.system(size: scaledFont(9), weight: .light, design: .monospaced))
                .tracking(2)
                .foregroundStyle(Color.white.opacity(0.18))
                .accessibilityLabel("For entertainment and mindfulness only")
        }
        .padding(.top, 20)
    }
    
    private var intentionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("✦ INTENTION")
                .font(.system(size: scaledFont(8), weight: .medium, design: .monospaced))
                .tracking(3.5)
                .foregroundStyle(Color.auraViolet.opacity(0.80))
                .accessibilityHidden(true)
            
            TextEditor(text: $viewModel.intention)
                .frame(minHeight: 70, maxHeight: 100)
                .font(.system(size: scaledFont(14), weight: .light))
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .foregroundStyle(Color.white.opacity(0.88))
                .textInputAutocapitalization(.sentences)
                .focused($isIntentionFocused)
                .accessibilityLabel("Enter your intention")
                .accessibilityHint("Type what you want to manifest")
        }
    }
    
    private var iterationsSection: some View {
        VStack(spacing: 2) {
            Text("TRANSMISSION CYCLES")
                .font(.system(size: scaledFont(8), weight: .medium, design: .monospaced))
                .tracking(3.5)
                .foregroundStyle(Color.auraBlue.opacity(0.80))
                .accessibilityHidden(true)
            
            HStack {
                Button(action: { viewModel.decrementIterations() }) {
                    Image(systemName: "minus")
                        .frame(width: 30, height: 30)
                        .accessibilityLabel("Decrease iterations")
                }
                .buttonStyle(.plain)
                .accessibilityHint("Decreases the number of transmission cycles")
                
                Text("\(viewModel.iterations)")
                    .font(.system(size: scaledFont(14), weight: .light, design: .monospaced))
                    .frame(minWidth: 40)
                    .accessibilityLabel("\(viewModel.iterations) cycles")
                    .accessibilityHidden(true)
                
                Button(action: { viewModel.incrementIterations() }) {
                    Image(systemName: "plus")
                        .frame(width: 30, height: 30)
                        .accessibilityLabel("Increase iterations")
                }
                .buttonStyle(.plain)
                .accessibilityHint("Increases the number of transmission cycles")
            }
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 10) {
            ZStack {
                if reduceMotion {
                    StaticProgressView(progress: viewModel.progress)
                } else {
                    ParticleField(progress: viewModel.progress)
                }
            }
            .frame(width: 280, height: 280)
            .accessibilityLabel("Transmission progress visualization")
            .accessibilityValue("\(Int(viewModel.progress * 100)) percent complete")
            
            VStack(spacing: 2) {
                Text(viewModel.formattedTime)
                    .font(.system(size: scaledFont(14), weight: .light, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.60))
                    .accessibilityLabel("Time remaining: \(viewModel.formattedTime)")
                
                ProgressView(value: viewModel.progress)
                    .frame(height: 2)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 10)
    }
    
    private var controlButtons: some View {
        VStack(spacing: 10) {
            Button(action: {
                isIntentionFocused = false
                #if os(iOS)
                hideKeyboard()
                #endif
                if viewModel.isRunning {
                    viewModel.stopTransmission()
                } else {
                    viewModel.startTransmission()
                }
            }) {
                Text(viewModel.isRunning ? "STOP TRANSMISSION" : "BEGIN TRANSMISSION")
                    .font(.system(size: scaledFont(12), weight: .semibold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(LinearGradient(
                        colors: viewModel.isRunning ? [Color.gray] : [.auraViolet, .auraBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .cornerRadius(8)
            }
            .accessibilityLabel(viewModel.isRunning ? "Stop transmission" : "Begin transmission")
            .accessibilityHint(viewModel.canStart ? "Starts the manifestation transmission" : "Please enter an intention first")
            .disabled(!viewModel.canStart && !viewModel.isRunning)
            
            Button(action: { viewModel.reset() }) {
                Text("RESET")
                    .font(.system(size: scaledFont(10), weight: .light, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(Color.white.opacity(0.60))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.20), lineWidth: 1))
            }
            .accessibilityLabel("Reset transmission")
            .accessibilityHint("Resets all settings and stops transmission")
        }
        .padding(.bottom, 10)
    }
    
    private func errorSection(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(Color.orange)
                .font(.system(size: scaledFont(24)))
            
            Text("Transmission Error")
                .font(.system(size: scaledFont(14), weight: .semibold))
                .foregroundStyle(Color.white)
            
            Text(message)
                .font(.system(size: scaledFont(12)))
                .foregroundStyle(Color.white.opacity(0.70))
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(Color.orange.opacity(0.15))
        .cornerRadius(8)
        .accessibilityLabel("Error: \(message)")
    }
    
    // MARK: - Helpers
    private func scaledFont(_ size: CGFloat) -> CGFloat {
        switch dynamicTypeSize {
        case .xSmall:
            return size * 0.8
        case .small:
            return size * 0.9
        case .medium:
            return size
        case .large:
            return size * 1.1
        case .xLarge:
            return size * 1.2
        case .xxLarge:
            return size * 1.3
        case .accessibility1:
            return size * 1.4
        case .accessibility2:
            return size * 1.5
        case .accessibility3:
            return size * 1.6
        @unknown default:
            return size
        }
    }
    
    #if os(iOS)
    private func hideKeyboard() {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .endEditing(true)
    }
    #endif
}

// MARK: - Static Progress View (for reduced motion)
struct StaticProgressView: View {
    var progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 2)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(colors: [.auraViolet, .auraBlue], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}
