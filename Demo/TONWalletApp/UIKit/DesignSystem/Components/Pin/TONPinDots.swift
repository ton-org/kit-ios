import SwiftUI

// PIN dot indicator from figma `40001176:24966`. Always 4 circles (12×12) in a 96×24 box,
// 16pt gap between them. Color reflects state:
//   • empty   → light gray (#EDEDF3 → tonBgLightGray)
//   • filled  → accent blue (#007AFF → tonBgBrand)
//   • error   → red         (#FF3B30 → tonRed)  — applied to all dots
struct TONPinDots: View {
    let filled: Int
    let length: Int
    let isError: Bool

    init(filled: Int, length: Int = 4, isError: Bool = false) {
        self.filled = filled
        self.length = length
        self.isError = isError
    }

    var body: some View {
        HStack(spacing: 16) {
            ForEach(0..<length, id: \.self) { index in
                Circle()
                    .fill(color(for: index))
                    .frame(width: 12, height: 12)
            }
        }
        .frame(height: 24)
        .modifier(ShakeIfErrorModifier(isError: isError))
        .animation(.easeOut(duration: 0.15), value: filled)
    }

    private func color(for index: Int) -> Color {
        if isError { return .tonRed }
        return index < filled ? .tonBgBrand : .tonBgLightGray
    }
}

private struct ShakeIfErrorModifier: ViewModifier {
    let isError: Bool
    @State private var trigger: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(travel: trigger))
            .animation(.linear(duration: 0.4), value: trigger)
            .onChange(of: isError) { newValue in
                if newValue { trigger += 1 }
            }
    }
}

private struct ShakeEffect: GeometryEffect {
    var travel: CGFloat
    var animatableData: CGFloat {
        get { travel }
        set { travel = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        let x = sin(travel * .pi * 5) * 10 * (1 - travel.truncatingRemainder(dividingBy: 1))
        return ProjectionTransform(CGAffineTransform(translationX: x, y: 0))
    }
}

#Preview {
    VStack(spacing: 32) {
        TONPinDots(filled: 0)
        TONPinDots(filled: 2)
        TONPinDots(filled: 4)
        TONPinDots(filled: 4, isError: true)
    }.padding()
}
