import SwiftUI
import Combine

@MainActor
final class Theme: ObservableObject {
    @Published var accentColor: Color = Color("Primary", bundle: .main)
    @Published var accentGradient: LinearGradient
    @Published var typography: Typography

    struct Typography {
        var headingFontName: String
        var bodyFontName: String
        var headingSize: CGFloat
        var bodySize: CGFloat
    }

    init() {
        accentGradient = LinearGradient(
            colors: [Color("Primary"), Color("PrimaryAccent")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        typography = Typography(
            headingFontName: "EBGaramond-Bold",
            bodyFontName: "EBGaramond-Regular",
            headingSize: 28,
            bodySize: 16
        )
    }

    func updateColors(primary: Color, accent: Color) {
        withAnimation(.easeInOut(duration: 0.25)) {
            accentColor = primary
            accentGradient = LinearGradient(colors: [primary, accent], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
