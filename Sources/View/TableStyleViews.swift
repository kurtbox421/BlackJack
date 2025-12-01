import SwiftUI

struct TableBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(red: 0.05, green: 0.2, blue: 0.08), Color(red: 0.02, green: 0.14, blue: 0.05)],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            RadialGradient(
                colors: [Color.white.opacity(0.08), Color.clear],
                center: .center,
                startRadius: 80,
                endRadius: 380
            )
        )
        .ignoresSafeArea()
    }
}

struct CardView: View {
    let card: Card?
    var isFaceDown: Bool = false

    private var suitColor: Color {
        guard let card else { return .white }
        return card.suit.color == "red" ? .red : .primary
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    isFaceDown
                        ? LinearGradient(colors: [Color(red: 0.14, green: 0.18, blue: 0.32), Color(red: 0.07, green: 0.1, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.white, Color(red: 0.96, green: 0.96, blue: 0.99)], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 8)
                .shadow(color: Color.white.opacity(0.2), radius: 2, x: 0, y: 1)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(isFaceDown ? Color(red: 0.45, green: 0.55, blue: 0.78) : Color.black.opacity(0.1), lineWidth: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                        .padding(3)
                )

            if isFaceDown {
                VStack(spacing: 6) {
                    Circle()
                        .fill(LinearGradient(colors: [Color(red: 0.9, green: 0.2, blue: 0.3), Color(red: 0.6, green: 0.1, blue: 0.2)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 24, height: 24)
                        .overlay(Image(systemName: "heart.fill").font(.system(size: 14, weight: .bold)).foregroundColor(.white))
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 46, height: 6)
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 40, height: 5)
                }
            } else if let card {
                VStack(alignment: .leading) {
                    Text("\(card.rank.label)\(card.suit.rawValue)")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(suitColor)
                        .padding(.top, 6)
                        .padding(.leading, 8)

                    Spacer()

                    Text(card.suit.rawValue)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(suitColor.opacity(0.75))
                        .frame(maxWidth: .infinity)

                    Spacer()

                    Text("\(card.rank.label)\(card.suit.rawValue)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(suitColor)
                        .rotationEffect(.degrees(180))
                        .padding(.bottom, 6)
                        .padding(.trailing, 8)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.vertical, 2)
            }
        }
        .frame(width: 80, height: 120)
    }
}

struct ChipButton: View {
    let amount: Int
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 0.95, green: 0.3, blue: 0.35), Color(red: 0.65, green: 0.05, blue: 0.12)],
                            center: .center,
                            startRadius: 8,
                            endRadius: 42
                        )
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)

                Circle()
                    .strokeBorder(Color.white.opacity(0.9), lineWidth: 4)
                    .padding(6)

                Text(label)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
            }
            .frame(width: 64, height: 64)
        }
        .buttonStyle(.plain)
    }
}
