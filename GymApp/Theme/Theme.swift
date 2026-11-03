import SwiftUI

/// Identidade visual do GymApp: paleta escura própria, com laranja para musculação
/// e verde-água pra cardio — dá pra reconhecer o tipo de dia num relance.
enum AppColor {
    static let background = Color("Background")
    static let surface = Color("Surface")
    static let surfaceElevated = Color("SurfaceElevated")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")

    /// Dias de musculação
    static let strength = Color("AccentStrength")
    /// Dias de cardio (corrida, pedal)
    static let cardio = Color("AccentCardio")
    /// Dias de descanso
    static let rest = Color("AccentRest")

    static let success = Color("SuccessColor")
    static let danger = Color("DangerColor")
}

enum AppFont {
    static func largeTitle(_ size: CGFloat = 32) -> Font { .system(size: size, weight: .heavy, design: .rounded) }
    static func title(_ size: CGFloat = 24) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func headline(_ size: CGFloat = 17) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func body(_ size: CGFloat = 16) -> Font { .system(size: size, weight: .regular, design: .rounded) }
    static func caption(_ size: CGFloat = 13) -> Font { .system(size: size, weight: .medium, design: .rounded) }
    /// Pra números (peso, reps, RPE) — monoespaçado pra não "dançar" enquanto digita/atualiza
    static func numeric(_ size: CGFloat = 16, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

enum AppMetrics {
    static let cornerRadius: CGFloat = 18
    static let smallCornerRadius: CGFloat = 12
    static let spacing: CGFloat = 14
}

extension RoutineKind {
    var accentColor: Color {
        switch self {
        case .lifting: return AppColor.strength
        case .cardio: return AppColor.cardio
        case .rest: return AppColor.rest
        }
    }

    var symbol: String {
        switch self {
        case .lifting: return "dumbbell.fill"
        case .cardio: return "figure.run"
        case .rest: return "moon.zzz.fill"
        }
    }
}

// MARK: - Modifiers

struct CardBackground: ViewModifier {
    var color: Color = AppColor.surface
    func body(content: Content) -> some View {
        content
            .padding(AppMetrics.spacing)
            .background(color, in: RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
    }
}

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
    }
}

extension View {
    func cardStyle(_ color: Color = AppColor.surface) -> some View { modifier(CardBackground(color: color)) }
    func screenBackground() -> some View { modifier(ScreenBackground()) }
}

// MARK: - Componentes

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = AppColor.strength
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.headline(16))
            .foregroundStyle(.black)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(color.opacity(configuration.isPressed ? 0.7 : 1), in: RoundedRectangle(cornerRadius: AppMetrics.smallCornerRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct TagView: View {
    let text: String
    var color: Color = AppColor.strength
    var systemImage: String?

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(text)
        }
        .font(AppFont.caption(12))
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.16), in: Capsule())
    }
}

struct SectionHeaderLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(AppColor.textSecondary)
            .tracking(0.6)
    }
}
