//
//  TutorialView.swift
//  TicTacToe
//
//  "How to play" for the Ultimate and Vanish variants. Each page replays a short scripted
//  game on the real board so players see the rule happen instead of reading about it.
//

import SwiftUI

private enum TutorialBoardState {
    case ultimate(UltimateBoard)
    case vanish(VanishBoard)
}

private struct TutorialFrame {
    let caption: String
    let board: TutorialBoardState
}

private struct TutorialPage: Identifiable {
    let id = UUID()
    let title: String
    let frames: [TutorialFrame]
}

struct TutorialView: View {
    let variant: GameVariant
    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss
    @State private var pageIndex = 0
    
    private var pages: [TutorialPage] {
        variant == .vanish ? Self.vanishPages : Self.ultimatePages
    }
    
    var body: some View {
        ZStack {
            AnimatedBackdrop(colors: progress.theme.background)
            
            VStack(spacing: 8) {
                HStack {
                    Text("HOW TO PLAY")
                        .font(gameFont(16))
                        .foregroundColor(.white.opacity(0.85))
                    Spacer()
                    Button("SKIP") { dismiss() }
                        .font(gameFont(14))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                TabView(selection: $pageIndex) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        TutorialPageView(page: page, theme: progress.theme, skin: progress.skin)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                
                Button {
                    if pageIndex < pages.count - 1 {
                        withAnimation { pageIndex += 1 }
                    } else {
                        dismiss()
                    }
                } label: {
                    Text(pageIndex < pages.count - 1 ? "NEXT" : "LET'S PLAY!")
                        .font(gameFont(24, weight: .black))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(palette: .green, cornerRadius: 22, depth: 8))
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
        .onAppear {
            AppAnalytics.shared.log(AnalyticsEvent.tutorialStart, ["variant": variant.name.lowercased()])
        }
        .onDisappear {
            // Did players finish the tutorial, or give up on which page? Shows where it loses people.
            AppAnalytics.shared.log(AnalyticsEvent.tutorialExit, [
                "variant": variant.name.lowercased(),
                "last_page": pageIndex + 1,
                "pages": pages.count,
                "completed": pageIndex == pages.count - 1
            ])
        }
    }
}

private struct TutorialPageView: View {
    let page: TutorialPage
    let theme: BoardTheme
    let skin: PieceSkin
    @State private var frameIndex = 0
    
    var body: some View {
        let frame = page.frames[min(frameIndex, page.frames.count - 1)]
        
        return VStack(spacing: 14) {
            Text(page.title)
                .font(gameFont(30, weight: .black))
                .foregroundColor(GamePalette.gold)
                .outlined(GamePalette.goldEdge, width: 2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .lineLimit(2)
            
            board(for: frame.board)
                .padding(10)
                .gamePanel(cornerRadius: 24)
                .padding(.horizontal, 24)
            
            Text(frame.caption)
                .font(gameFont(18, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 84, alignment: .top)
                .padding(.horizontal, 28)
                .id(frameIndex) // fades between captions
                .transition(.opacity)
            
            Spacer(minLength: 0)
        }
        .padding(.top, 4)
        .animation(.spring(response: 0.4, dampingFraction: 0.65), value: frameIndex)
        .task(id: page.id) {
            // Loop the scripted frames while this page is on screen
            guard page.frames.count > 1 else { return }
            frameIndex = 0
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_600_000_000)
                guard !Task.isCancelled else { return }
                frameIndex = (frameIndex + 1) % page.frames.count
            }
        }
    }
    
    @ViewBuilder
    private func board(for state: TutorialBoardState) -> some View {
        switch state {
        case .ultimate(let board):
            UltimateBoardView(board: board, theme: theme, skin: skin, hint: nil, interactive: false) { _ in }
        case .vanish(let board):
            VanishDemoBoard(board: board, theme: theme, skin: skin)
        }
    }
}

/// A small, non-interactive 3x3 board for the Vanish tutorial
private struct VanishDemoBoard: View {
    let board: VanishBoard
    let theme: BoardTheme
    let skin: PieceSkin
    
    var body: some View {
        let position = board.position
        let winning = Set(board.winningLine ?? [])
        let fading = board.winner == nil ? board.fadingSquares : []
        
        return VStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { column in
                        let square = row * 3 + column
                        tile(position[square], winning: winning.contains(square), fading: fading.contains(square))
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxHeight: 340)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: board)
    }
    
    private func tile(_ piece: Piece, winning: Bool, fading: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: winning ? [Color(red: 1.0, green: 0.95, blue: 0.5), GamePalette.goldDeep]
                                                     : [theme.tileTop, theme.tileBottom],
                                     startPoint: .top, endPoint: .bottom))
            
            if let glyph = skin.glyph(for: piece) {
                Text(glyph).font(.system(size: 44)).transition(.scale(scale: 0.1).combined(with: .opacity))
            } else if piece == .X {
                XMark()
                    .stroke(theme.xColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .padding(24)
                    .transition(.scale(scale: 0.1).combined(with: .opacity))
            } else if piece == .O {
                Circle()
                    .strokeBorder(theme.oColor, lineWidth: 12)
                    .padding(20)
                    .transition(.scale(scale: 0.1).combined(with: .opacity))
            }
            
            if fading {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.black.opacity(0.4), style: StrokeStyle(lineWidth: 3, dash: [6, 6]))
                    .pulsing(1.03)
                Image(systemName: "hourglass")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.black.opacity(0.55))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(6)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Scripted content
extension TutorialView {
    /// Boards after each move of a scripted Ultimate game; index 0 is the empty board
    fileprivate static func ultimateStates(_ moves: [UltimateMove]) -> [UltimateBoard] {
        var board = UltimateBoard()
        var states = [board]
        for move in moves {
            board = board.playing(move)
            states.append(board)
        }
        return states
    }
    
    /// The same script the app would accept as legal moves: X ends up claiming the middle board
    /// with a diagonal, which sends O to a decided board and so gives O a free choice.
    fileprivate static var ultimatePages: [TutorialPage] {
        let s = ultimateStates([UltimateMove(board: 4, cell: 0), UltimateMove(board: 0, cell: 4),
                                UltimateMove(board: 4, cell: 8), UltimateMove(board: 8, cell: 4),
                                UltimateMove(board: 4, cell: 4)])
        let claimed = UltimateBoard.demo(results: [4: .won(.X)])
        let threeInARow = UltimateBoard.demo(results: [0: .won(.X), 4: .won(.X), 8: .won(.X), 2: .draw])
        
        return [
            TutorialPage(title: "9 GAMES IN 1", frames: [
                TutorialFrame(caption: "Ultimate is nine small tic-tac-toe boards inside one big board.", board: .ultimate(s[0])),
                TutorialFrame(caption: "Win a small board to claim that big square.", board: .ultimate(claimed))
            ]),
            TutorialPage(title: "WHERE YOU PLAY MATTERS", frames: [
                TutorialFrame(caption: "X plays the top-left cell of the middle board…", board: .ultimate(s[0])),
                TutorialFrame(caption: "…so O must reply in the top-left board. It glows gold: that's the only board O can use.", board: .ultimate(s[1])),
                TutorialFrame(caption: "O plays the center cell, which sends X back to the middle board.", board: .ultimate(s[2])),
                TutorialFrame(caption: "X plays the bottom-right cell, so O must go to the bottom-right board.", board: .ultimate(s[3]))
            ]),
            TutorialPage(title: "CLAIM A BOARD", frames: [
                TutorialFrame(caption: "X holds two corners of the middle board and needs the center.", board: .ultimate(s[4])),
                TutorialFrame(caption: "X takes it and completes a diagonal. The middle board is claimed!", board: .ultimate(s[5])),
                TutorialFrame(caption: "O would be sent to the middle board, but it's already decided, so O can play in ANY open board.", board: .ultimate(s[5]))
            ]),
            TutorialPage(title: "WIN THE GAME", frames: [
                TutorialFrame(caption: "Claim three big squares in a row, across, down or diagonally, to win.", board: .ultimate(threeInARow)),
                TutorialFrame(caption: "A small board that fills up with no winner (=) counts for nobody.", board: .ultimate(threeInARow))
            ]),
            TutorialPage(title: "PRO TIPS", frames: [
                TutorialFrame(caption: "Before you tap, look at which board your move sends your opponent to.", board: .ultimate(s[2])),
                TutorialFrame(caption: "Don't send them to a board where they are about to win.", board: .ultimate(s[3])),
                TutorialFrame(caption: "Sending them to a decided board gives them a free move. Use it carefully!", board: .ultimate(s[5]))
            ])
        ]
    }
    
    fileprivate static var vanishPages: [TutorialPage] {
        var board = VanishBoard()
        var states = [board]
        for square in [0, 4, 1, 8, 5, 7, 6] { // X0 O4 X1 O8 X5 O7 X6
            board = board.playing(square)
            states.append(board)
        }
        let win = VanishBoard(x: [0, 4, 8], o: [1, 2, 3], turn: .O)
        
        return [
            TutorialPage(title: "ONLY 3 MARKS", frames: [
                TutorialFrame(caption: "Take turns placing X and O, just like normal tic-tac-toe.", board: .vanish(states[3])),
                TutorialFrame(caption: "But each player can only have 3 marks on the board at once.", board: .vanish(states[5]))
            ]),
            TutorialPage(title: "THE OLDEST VANISHES", frames: [
                TutorialFrame(caption: "Both players have 3 marks. The dashed ones are the oldest.", board: .vanish(states[6])),
                TutorialFrame(caption: "X places a 4th mark, so X's oldest mark disappears!", board: .vanish(states[7]))
            ]),
            TutorialPage(title: "3 IN A ROW WINS", frames: [
                TutorialFrame(caption: "Get your three marks in a row to win.", board: .vanish(win)),
                TutorialFrame(caption: "There are no draws, because the board keeps changing. Plan ahead!", board: .vanish(win))
            ])
        ]
    }
}
