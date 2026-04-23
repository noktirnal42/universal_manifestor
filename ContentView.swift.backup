import SwiftUI
import Combine

// MARK: – Design tokens

fileprivate extension Color {
    static let auraViolet = Color(hue: 0.76, saturation: 0.62, brightness: 0.88)
    static let auraBlue   = Color(hue: 0.60, saturation: 0.72, brightness: 1.00)
    static let auraTeal   = Color(hue: 0.52, saturation: 0.68, brightness: 0.95)
}

private struct GlassPanel: ViewModifier {
    var accented: Bool = false
    func body(content: Content) -> some View {
        content
            .background(Color.white.opacity(0.036))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14).strokeBorder(
                    LinearGradient(
                        colors: accented
                            ? [Color.auraViolet.opacity(0.55), Color.auraBlue.opacity(0.30), Color.clear]
                            : [Color.white.opacity(0.09), Color.white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            )
    }
}

private extension View {
    func glassPanel(accented: Bool = false) -> some View {
        modifier(GlassPanel(accented: accented))
    }
}

// MARK: – ContentView

struct ContentView: View {
    @State private var intention:        String = ""
    @State private var iterations:       Int    = 7
    @State private var remainingSeconds: Double = 35.0   // 7 × 5 s
    @State private var isRunning:        Bool   = false
    @State private var timerCancellable: AnyCancellable?
    @State private var startedAt:        Date?

    private let secondsPerIteration: Double = 5.0
    private let audio = AudioEngine.shared

    var transmissionSeconds: Double { Double(max(1, iterations)) * secondsPerIteration }

    var progress: Double {
        guard transmissionSeconds > 0 else { return 0 }
        return min(1.0, max(0.0, 1.0 - (remainingSeconds / transmissionSeconds)))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 14) {

                // ── Title ─────────────────────────────────────────────────
                VStack(spacing: 5) {
                    Text("UNIVERSAL MANIFESTOR")
                        .font(.system(size: 20, weight: .ultraLight))
                        .tracking(7)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.auraViolet, .auraBlue, .auraTeal],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                    Text("for entertainment & mindfulness only")
                        .font(.system(size: 9, weight: .light, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(Color.white.opacity(0.18))
                }
                .padding(.top, 20)

                // ── Intention ─────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 8) {
                    Text("✦  INTENTION")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .tracking(3.5)
                        .foregroundStyle(Color.auraViolet.opacity(0.80))
                    #if os(iOS)
                    TextEditor(text: $intention)
                        .frame(minHeight: 70, maxHeight: 100)
                        .font(.system(size: 14, weight: .light))
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .foregroundStyle(Color.white.opacity(0.88))
                        .textInputAutocapitalization(.sentences)
                    #else
                    TextEditor(text: $intention)
                        .frame(minHeight: 70, maxHeight: 100)
                        .font(.system(size: 14, weight: .light))
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .foregroundStyle(Color.white.opacity(0.88))
                    #endif
                }
                .padding(14)
                .glassPanel(accented: true)
                .padding(.horizontal, 16)

                // ── Iterations ────────────────────────────────────────────
                VStack(spacing: 10) {
                    HStack {
                        Text("✦  ITERATIONS")
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .tracking(3.5)
                            .foregroundStyle(Color.auraBlue.opacity(0.80))
                        Spacer()
                    }

                    // Large number stepper
                    HStack(spacing: 24) {
                        Button(action: {
                            withAnimation(.spring(duration: 0.22)) { iterations = max(1, iterations - 1) }
                        }) {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 26, weight: .ultraLight))
                                .foregroundStyle(Color.auraViolet.opacity(iterations > 1 ? 0.85 : 0.2))
                        }
                        .buttonStyle(.plain)
                        .disabled(isRunning || iterations <= 1)

                        VStack(spacing: 2) {
                            Text("\(iterations)")
                                .font(.system(size: 52, weight: .ultraLight, design: .monospaced))
                                .foregroundStyle(.white)
                                .contentTransition(.numericText())
                                .frame(minWidth: 90)
                                .multilineTextAlignment(.center)
                            Text("iterations")
                                .font(.system(size: 9, weight: .light, design: .monospaced))
                                .tracking(2)
                                .foregroundStyle(Color.white.opacity(0.25))
                        }

                        Button(action: {
                            withAnimation(.spring(duration: 0.22)) { iterations = min(999, iterations + 1) }
                        }) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 26, weight: .ultraLight))
                                .foregroundStyle(Color.auraViolet.opacity(iterations < 999 ? 0.85 : 0.2))
                        }
                        .buttonStyle(.plain)
                        .disabled(isRunning || iterations >= 999)
                    }

                    // Sacred-number presets
                    HStack(spacing: 6) {
                        ForEach([3, 7, 21, 33, 108], id: \.self) { n in
                            Button(action: {
                                withAnimation(.spring(duration: 0.22)) { iterations = n }
                            }) {
                                Text("\(n)")
                                    .font(.system(size: 10,
                                                  weight: iterations == n ? .medium : .light,
                                                  design: .monospaced))
                                    .foregroundStyle(iterations == n ? Color.auraBlue : Color.white.opacity(0.32))
                                    .padding(.horizontal, 9).padding(.vertical, 4)
                                    .background(iterations == n ? Color.auraBlue.opacity(0.14) : Color.clear)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().strokeBorder(
                                        iterations == n ? Color.auraBlue.opacity(0.45) : Color.white.opacity(0.08),
                                        lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .disabled(isRunning)
                        }
                    }

                    // Computed time output
                    HStack(spacing: 6) {
                        Circle().fill(Color.auraViolet).frame(width: 3, height: 3)
                        Text(isRunning
                             ? "\(formattedTime(remainingSeconds)) remaining"
                             : "manifestation time  ·  \(formattedTime(transmissionSeconds))")
                            .font(.system(size: 10, weight: .light, design: .monospaced))
                            .tracking(1.5)
                            .foregroundStyle(isRunning
                                             ? Color.auraBlue.opacity(0.8)
                                             : Color.auraViolet.opacity(0.65))
                            .contentTransition(.numericText())
                        Circle().fill(Color.auraViolet).frame(width: 3, height: 3)
                    }
                }
                .padding(14)
                .glassPanel()
                .padding(.horizontal, 16)

                // ── Orb ───────────────────────────────────────────────────
                ZStack {
                    OrbitalField3D(progress: progress)
                        .frame(minHeight: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [.auraViolet.opacity(0.45), .clear, .auraTeal.opacity(0.35)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )

                    VStack(spacing: 10) {
                        Spacer()
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.07))
                                Capsule()
                                    .fill(LinearGradient(
                                        colors: [.auraViolet, .auraBlue, .auraTeal],
                                        startPoint: .leading, endPoint: .trailing
                                    ))
                                    .frame(width: max(progress > 0 ? 4 : 0,
                                                      geo.size.width * progress))
                                    .animation(.linear(duration: 0.05), value: progress)
                            }
                        }
                        .frame(height: 2)
                        .padding(.horizontal, 28)

                        Group {
                            if isRunning {
                                Text("✦  manifesting  ·  \(formattedTime(remainingSeconds))  ✦")
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.auraViolet, .auraTeal],
                                            startPoint: .leading, endPoint: .trailing
                                        )
                                    )
                            } else {
                                Text("· · ·  idle  · · ·")
                                    .foregroundStyle(Color.white.opacity(0.25))
                            }
                        }
                        .font(.system(size: 11, weight: .ultraLight, design: .monospaced))
                        .tracking(3)
                        .padding(.bottom, 14)
                    }
                }
                .padding(.horizontal, 16)

                // ── Controls ──────────────────────────────────────────────
                HStack(spacing: 10) {
                    Button(action: startOrResume) {
                        HStack(spacing: 7) {
                            Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 11))
                            Text(isRunning ? "Pause" : "Begin")
                                .font(.system(size: 13, weight: .light))
                                .tracking(1)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 9)
                        .background {
                            if isRunning {
                                Capsule().fill(Color.white.opacity(0.10))
                            } else {
                                Capsule().fill(
                                    LinearGradient(
                                        colors: [.auraViolet.opacity(0.85), .auraBlue.opacity(0.85)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                            }
                        }
                        .overlay(
                            Capsule().strokeBorder(
                                isRunning ? Color.white.opacity(0.15) : Color.auraViolet.opacity(0.55),
                                lineWidth: 1
                            )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(intention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isRunning)

                    Button(action: reset) {
                        HStack(spacing: 6) {
                            Image(systemName: "gobackward").font(.system(size: 10))
                            Text("Reset").font(.system(size: 12, weight: .light)).tracking(1)
                        }
                        .foregroundStyle(Color.white.opacity(0.55))
                        .padding(.horizontal, 16).padding(.vertical, 9)
                        .background(Color.white.opacity(0.04))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(!isRunning && progress == 0)

                    Spacer()

                    ShareLink(items: [intention.isEmpty
                                      ? "Setting an intention ✨"
                                      : "My intention: \(intention)"]) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.50))
                            .padding(9)
                            .background(Color.white.opacity(0.04))
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
            }
        }
        .preferredColorScheme(.dark)
        #if os(iOS)
        .padding(.bottom, 8)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        #endif
        .onDisappear {
            timerCancellable?.cancel()
            audio.stop()
        }
        .onChange(of: iterations) { _ in
            if !isRunning { remainingSeconds = transmissionSeconds }
        }
        .onAppear { remainingSeconds = transmissionSeconds }
    }
    
    private func startOrResume() {
        if isRunning {
            // Pause
            isRunning = false
            timerCancellable?.cancel()
            timerCancellable = nil
            audio.pause()
            return
        }
        // Start (or resume)
        let isFreshStart = progress == 0.0 || progress >= 1.0
        if progress >= 1.0 {
            // If already complete, reset first
            reset()
        }
        isRunning = true
        startedAt = Date()

        if isFreshStart {
            audio.start()
        } else {
            audio.resume()
        }

        timerCancellable = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                remainingSeconds = max(0, remainingSeconds - 0.05)
                audio.updateProgress(Float(progress))
                if remainingSeconds <= 0 {
                    isRunning = false
                    timerCancellable?.cancel()
                    timerCancellable = nil
                    celebrate()
                }
            }
    }
    
    private func reset() {
        isRunning = false
        timerCancellable?.cancel()
        timerCancellable = nil
        remainingSeconds = transmissionSeconds
        intention = ""
        audio.stop()
    }
    
    private func formattedTime(_ seconds: Double) -> String {
        let s = Int(seconds.rounded(.up))
        let m = s / 60
        let r = s % 60
        return String(format: "%d:%02d", m, r)
    }
    
    private func celebrate() {
        audio.complete()
        #if os(iOS)
        triggerIOSSuccessHaptic()
        #endif
    }
}

#if os(iOS)
import UIKit
private func triggerIOSSuccessHaptic() {
    let gen = UINotificationFeedbackGenerator()
    gen.prepare()
    gen.notificationOccurred(.success)
}
#endif
