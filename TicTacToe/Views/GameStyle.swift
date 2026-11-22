//
//  GameStyle.swift
//  TicTacToe
//
//  Shared look-and-feel for the whole app: saturated gradients, chunky 3D buttons,
//  outlined display type, glossy panels, springy motion and haptics on every press.
//

import SwiftUI

// MARK: - Palette
enum GamePalette {
    static let skyTop = Color(red: 0.12, green: 0.50, blue: 0.95)
    static let skyBottom = Color(red: 0.0, green: 0.74, blue: 0.78)
    static let panel = Color(red: 0.06, green: 0.20, blue: 0.40)
    static let panelLight = Color(red: 0.13, green: 0.35, blue: 0.60)
    static let gold = Color(red: 1.0, green: 0.82, blue: 0.22)
    static let goldDeep = Color(red: 0.95, green: 0.55, blue: 0.08)
    static let goldEdge = Color(red: 0.62, green: 0.32, blue: 0.02)
    static let ink = Color(red: 0.03, green: 0.10, blue: 0.25)
}

struct ButtonPalette {
    let top: Color
    let bottom: Color
    let edge: Color
    
    static let green = ButtonPalette(top: Color(red: 0.55, green: 0.95, blue: 0.30),
                                     bottom: Color(red: 0.25, green: 0.75, blue: 0.20),
                                     edge: Color(red: 0.12, green: 0.45, blue: 0.12))
    static let blue = ButtonPalette(top: Color(red: 0.40, green: 0.75, blue: 1.0),
                                    bottom: Color(red: 0.15, green: 0.50, blue: 0.95),
                                    edge: Color(red: 0.08, green: 0.25, blue: 0.65))
    static let orange = ButtonPalette(top: Color(red: 1.0, green: 0.75, blue: 0.25),
                                      bottom: Color(red: 1.0, green: 0.50, blue: 0.10),
                                      edge: Color(red: 0.70, green: 0.30, blue: 0.05))
    static let red = ButtonPalette(top: Color(red: 1.0, green: 0.45, blue: 0.45),
                                   bottom: Color(red: 0.90, green: 0.20, blue: 0.25),
                                   edge: Color(red: 0.55, green: 0.08, blue: 0.15))
    static let purple = ButtonPalette(top: Color(red: 0.75, green: 0.50, blue: 1.0),
                                      bottom: Color(red: 0.55, green: 0.28, blue: 0.90),
                                      edge: Color(red: 0.30, green: 0.12, blue: 0.55))
    static let gold = ButtonPalette(top: Color(red: 1.0, green: 0.92, blue: 0.45),
                                    bottom: Color(red: 1.0, green: 0.72, blue: 0.12),
                                    edge: Color(red: 0.75, green: 0.45, blue: 0.05))
    static let gray = ButtonPalette(top: Color(red: 0.70, green: 0.72, blue: 0.85),
                                    bottom: Color(red: 0.50, green: 0.52, blue: 0.70),
                                    edge: Color(red: 0.28, green: 0.30, blue: 0.45))
}

// MARK: - Text and panels
extension View {
    /// Thick cartoon outline around text/icons
    func outlined(_ color: Color = Color.black.opacity(0.45), width: CGFloat = 2) -> some View {
        self.shadow(color: color, radius: 0, x: width, y: 0)
            .shadow(color: color, radius: 0, x: -width, y: 0)
            .shadow(color: color, radius: 0, x: 0, y: width)
            .shadow(color: color, radius: 0, x: 0, y: -width)
    }
    
    func gamePanel(cornerRadius: CGFloat = 24, fill: Color = GamePalette.panel) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(fill)
                .overlay(RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 3))
                .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 6)
        )
    }
    
    func pulsing(_ scale: CGFloat = 1.06) -> some View {
        modifier(PulseModifier(scale: scale))
    }
    
    func bobbing(distance: CGFloat = 6, delay: Double = 0) -> some View {
        modifier(BobModifier(distance: distance, delay: delay))
    }
}

func gameFont(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
    .system(size: size, weight: weight, design: .rounded)
}

struct PulseModifier: ViewModifier {
    let scale: CGFloat
    @State private var on = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(on ? scale : 1)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: on)
            .onAppear { on = true }
    }
}

struct BobModifier: ViewModifier {
    let distance: CGFloat
    let delay: Double
    @State private var up = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: up ? -distance : distance)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(delay), value: up)
            .onAppear { up = true }
    }
}

// MARK: - Chunky 3D button
struct ChunkyButtonStyle: ButtonStyle {
    var palette: ButtonPalette = .green
    var cornerRadius: CGFloat = 18
    var depth: CGFloat = 6
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        let colors = isEnabled ? palette : .gray
        let pressed = configuration.isPressed
        
        return configuration.label
            .font(gameFont(20))
            .foregroundColor(.white)
            .outlined(Color.black.opacity(0.35), width: 1.5)
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(LinearGradient(colors: [colors.top, colors.bottom], startPoint: .top, endPoint: .bottom))
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: max(cornerRadius - 4, 4))
                            .fill(LinearGradient(colors: [Color.white.opacity(0.5), Color.white.opacity(0)],
                                                 startPoint: .top, endPoint: .bottom))
                            .frame(height: 18)
                            .padding(.horizontal, 6)
                            .padding(.top, 3)
                    }
                    .overlay(RoundedRectangle(cornerRadius: cornerRadius)
                                .strokeBorder(Color.white.opacity(0.4), lineWidth: 1.5))
            )
            .offset(y: pressed ? depth - 2 : 0)
            .background(RoundedRectangle(cornerRadius: cornerRadius).fill(colors.edge).offset(y: depth))
            .padding(.bottom, depth)
            .scaleEffect(pressed ? 0.97 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: pressed)
            .onChange(of: pressed) { _, isPressed in
                if isPressed { Haptics.tap() }
            }
    }
}

// MARK: - Currency and badges
struct CoinIcon: View {
    var size: CGFloat = 22
    
    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [Color(red: 1.0, green: 0.95, blue: 0.5), GamePalette.goldDeep],
                                         startPoint: .top, endPoint: .bottom))
            Circle().strokeBorder(GamePalette.goldEdge.opacity(0.8), lineWidth: max(size * 0.08, 1.5))
            Image(systemName: "star.fill")
                .font(.system(size: size * 0.5, weight: .black))
                .foregroundColor(GamePalette.goldEdge.opacity(0.8))
        }
        .frame(width: size, height: size)
        .shadow(color: Color.black.opacity(0.3), radius: 0, x: 0, y: 2)
    }
}

struct CoinPill: View {
    let amount: Int
    var onTap: (() -> Void)?
    
    var body: some View {
        if let onTap {
            Button(action: onTap) { pill }.buttonStyle(.plain)
        } else {
            pill
        }
    }
    
    private var pill: some View {
        HStack(spacing: 6) {
            CoinIcon(size: 26)
            Text("\(amount)")
                .font(gameFont(18))
                .foregroundColor(.white)
                .outlined(Color.black.opacity(0.4), width: 1)
            if onTap != nil {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(ButtonPalette.green.bottom))
            }
        }
        .padding(.leading, 4)
        .padding(.trailing, onTap == nil ? 14 : 4)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.black.opacity(0.35))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 2)))
    }
}

struct LevelBadge: View {
    let level: Int
    let progress: Double
    var size: CGFloat = 58
    
    var body: some View {
        ZStack {
            Circle().fill(Color.black.opacity(0.35))
            Circle().stroke(Color.white.opacity(0.2), lineWidth: 6)
            Circle()
                .trim(from: 0, to: max(progress, 0.03))
                .stroke(GamePalette.gold, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle()
                .fill(LinearGradient(colors: [Color(red: 0.45, green: 0.80, blue: 1.0), GamePalette.panelLight],
                                     startPoint: .top, endPoint: .bottom))
                .padding(8)
            Text("\(level)")
                .font(gameFont(size * 0.38, weight: .black))
                .foregroundColor(.white)
                .outlined(GamePalette.ink, width: 1.5)
        }
        .frame(width: size, height: size)
    }
}

struct RibbonTitle: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(gameFont(18))
            .foregroundColor(.white)
            .outlined(GamePalette.ink, width: 1.5)
            .padding(.horizontal, 28)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(LinearGradient(colors: [ButtonPalette.purple.top, ButtonPalette.purple.bottom],
                                         startPoint: .top, endPoint: .bottom))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.4), lineWidth: 2))
                    .shadow(color: Color.black.opacity(0.3), radius: 0, x: 0, y: 4)
            )
    }
}

struct CloseButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark").font(.system(size: 18, weight: .black))
        }
        .buttonStyle(ChunkyButtonStyle(palette: .red, cornerRadius: 14, depth: 4))
    }
}

// MARK: - Backgrounds and effects
struct AnimatedBackdrop: View {
    var colors: [Color] = [GamePalette.skyTop, GamePalette.skyBottom]
    
    private struct Floater {
        let x: Double
        let speed: Double
        let size: CGFloat
        let phase: Double
        let symbol: String
    }
    
    private let floaters: [Floater] = (0..<16).map { i in
        func rand(_ k: Double) -> Double {
            let v = sin(Double(i) * 12.9898 + k * 78.233) * 43758.5453
            return v - v.rounded(.down)
        }
        return Floater(x: rand(1), speed: 0.012 + rand(2) * 0.025, size: 28 + CGFloat(rand(3)) * 44,
                       phase: rand(4), symbol: i % 2 == 0 ? "xmark" : "circle")
    }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
            TimelineView(.animation) { context in
                GeometryReader { geo in
                    let t = context.date.timeIntervalSinceReferenceDate
                    ForEach(floaters.indices, id: \.self) { i in
                        let f = floaters[i]
                        let progress = (f.phase + t * f.speed).truncatingRemainder(dividingBy: 1)
                        Image(systemName: f.symbol)
                            .font(.system(size: f.size, weight: .heavy))
                            .foregroundColor(Color.white.opacity(0.10))
                            .rotationEffect(.degrees(t * 10 + f.phase * 360))
                            .position(x: f.x * geo.size.width, y: geo.size.height * (1.1 - progress * 1.2))
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct ConfettiView: View {
    @State private var start = Date()
    private let colors: [Color] = [.red, .yellow, .green, .cyan, .pink, .orange, .purple]
    
    private func rand(_ i: Int, _ k: Double) -> Double {
        let v = sin(Double(i) * 12.9898 + k * 78.233) * 43758.5453
        return v - v.rounded(.down)
    }
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSince(start)
                guard t < 4.5 else { return }
                for i in 0..<70 {
                    let delay = rand(i, 3) * 0.8
                    guard t > delay else { continue }
                    let x = rand(i, 1) * size.width + sin(t * 3 + Double(i)) * 18
                    let y = -20 + (t - delay) * (220 + rand(i, 2) * 220)
                    var piece = context
                    piece.translateBy(x: x, y: y)
                    piece.rotate(by: .radians(t * (2 + rand(i, 4) * 4)))
                    piece.fill(Path(CGRect(x: -4, y: -6, width: 8, height: 12)),
                               with: .color(colors[i % colors.count]))
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

struct RaysView: View {
    var color: Color = GamePalette.gold
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let angle = timeline.date.timeIntervalSinceReferenceDate * 15
                let center = CGPoint(x: size.width / 2, y: size.height * 0.38)
                let radius = max(size.width, size.height)
                for i in 0..<12 {
                    var path = Path()
                    path.move(to: center)
                    path.addArc(center: center, radius: radius,
                                startAngle: .degrees(angle + Double(i) * 30),
                                endAngle: .degrees(angle + Double(i) * 30 + 14),
                                clockwise: false)
                    path.closeSubpath()
                    context.fill(path, with: .color(color.opacity(0.28)))
                }
            }
        }
        .mask(RadialGradient(colors: [.white, .clear], center: UnitPoint(x: 0.5, y: 0.38),
                             startRadius: 40, endRadius: 420))
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

struct XMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return path
    }
}

/// Three stars that pop in one after another, with a haptic for each earned star
struct StarRow: View {
    let count: Int
    @State private var shown = 0
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                let lit = shown > i && i < count
                Image(systemName: "star.fill")
                    .font(.system(size: i == 1 ? 64 : 46, weight: .black))
                    .foregroundColor(lit ? GamePalette.gold : Color.black.opacity(0.35))
                    .outlined(lit ? GamePalette.goldEdge : Color.black.opacity(0.2), width: 2)
                    .scaleEffect(shown > i ? 1 : 0.1)
                    .offset(y: i == 1 ? -10 : 0)
                    .rotationEffect(.degrees(i == 0 ? -12 : (i == 2 ? 12 : 0)))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: shown)
        .task {
            for i in 0..<3 {
                try? await Task.sleep(nanoseconds: 350_000_000)
                shown = i + 1
                if i < count { Haptics.tap() }
            }
        }
    }
}
