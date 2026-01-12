import SwiftUI

struct UsagePopoverView: View {
    @ObservedObject var usageManager = UsageManager.shared

    var body: some View {
        ZStack {
            // Glassmorphic background
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)

            // Gradient overlay
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.15),
                    Color.blue.opacity(0.1),
                    Color.cyan.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Content
            VStack(spacing: 0) {
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                if usageManager.isLoading && usageManager.currentUsage == nil {
                    loadingView
                } else if let error = usageManager.errorMessage {
                    errorView(error)
                } else if let usage = usageManager.currentUsage {
                    ScrollView {
                        VStack(spacing: 16) {
                            sessionCard(usage)
                            weeklyCard(usage)
                            if usage.sonnetPercentage > 0 {
                                sonnetCard(usage)
                            }
                        }
                        .padding(20)
                    }
                } else {
                    emptyStateView
                }

                footerView
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
        }
        .frame(width: 360, height: 400)
    }

    // MARK: - Header

    var headerView: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Claude Usage")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Claude Max")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: { usageManager.fetchUsage() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(usageManager.isLoading ? 360 : 0))
                    .animation(usageManager.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: usageManager.isLoading)
            }
            .buttonStyle(.plain)
            .padding(8)
            .background(Color.primary.opacity(0.05))
            .clipShape(Circle())
        }
    }

    // MARK: - Session Card

    func sessionCard(_ usage: ClaudeUsage) -> some View {
        UsageCard(
            title: "Current Session",
            percentage: usage.sessionPercentage,
            resetText: usage.sessionReset.isEmpty ? nil : "Resets \(usage.sessionReset)",
            gradient: [.purple, .pink],
            icon: "clock.fill"
        )
    }

    // MARK: - Weekly Card

    func weeklyCard(_ usage: ClaudeUsage) -> some View {
        UsageCard(
            title: "Weekly Limit (All Models)",
            percentage: usage.weeklyPercentage,
            resetText: usage.weeklyReset.isEmpty ? nil : "Resets \(usage.weeklyReset)",
            gradient: [.blue, .cyan],
            icon: "calendar"
        )
    }

    // MARK: - Sonnet Card

    func sonnetCard(_ usage: ClaudeUsage) -> some View {
        UsageCard(
            title: "Weekly (Sonnet Only)",
            percentage: usage.sonnetPercentage,
            resetText: nil,
            gradient: [.orange, .yellow],
            icon: "sparkles"
        )
    }

    // MARK: - States

    var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Fetching usage from Claude...")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Text("This may take a few seconds")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text("Error")
                .font(.system(size: 16, weight: .semibold))

            Text(error)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Retry") {
                usageManager.fetchUsage()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No usage data")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            Button("Fetch Usage") {
                usageManager.fetchUsage()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Footer

    var footerView: some View {
        HStack {
            if let usage = usageManager.currentUsage {
                Text("Updated \(usage.lastUpdated.formatted(.relative(presentation: .named)))")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: { NSApplication.shared.terminate(nil) }) {
                Text("Quit")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Usage Card

struct UsageCard: View {
    let title: String
    let percentage: Double
    let resetText: String?
    let gradient: [Color]
    let icon: String

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(
                            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )

                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)

                    Spacer()

                    Text("\(Int(percentage))%")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.primary.opacity(0.1))
                            .frame(height: 12)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: geometry.size.width * min(percentage / 100, 1.0), height: 12)
                            .animation(.easeInOut(duration: 0.5), value: percentage)
                    }
                }
                .frame(height: 12)

                if let reset = resetText {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)

                        Text(reset)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.primary.opacity(0.05))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
    }
}

// MARK: - Visual Effect Blur

struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

#Preview {
    UsagePopoverView()
        .frame(width: 360, height: 400)
}
