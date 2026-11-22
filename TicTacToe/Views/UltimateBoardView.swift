//
//  UltimateBoardView.swift
//  TicTacToe
//
//  The 9x9 board for Ultimate Tic-Tac-Toe. Mini-boards the current player may play in
//  glow gold, decided mini-boards show a big X or O, and the last move is outlined.
//

import SwiftUI

struct UltimateBoardView: View {
    let board: UltimateBoard
    let theme: BoardTheme
    let skin: PieceSkin
    let hint: UltimateMove?
    let interactive: Bool
    let onTap: (UltimateMove) -> Void
    
    var body: some View {
        let bigLine = board.winningLine ?? []
        return VStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { column in
                        let index = row * 3 + column
                        miniBoard(index, inWinningLine: bigLine.contains(index))
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func miniBoard(_ index: Int, inWinningLine: Bool) -> some View {
        let result = board.results[index]
        let playable = board.outcome == nil && board.isPlayable(index)
        let highlighted = playable || inWinningLine
        
        return ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(playable ? GamePalette.gold.opacity(0.35) : Color.black.opacity(0.25))
            
            VStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 3) {
                        ForEach(0..<3, id: \.self) { column in
                            cell(index, row * 3 + column, playable: playable)
                        }
                    }
                }
            }
            .padding(4)
            .opacity(result == .open ? 1 : 0.25)
            
            decidedMark(result)
        }
        .overlay(RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(highlighted ? GamePalette.gold : Color.white.opacity(0.12),
                                  lineWidth: highlighted ? 3 : 1))
        .aspectRatio(1, contentMode: .fit)
        .animation(.easeInOut(duration: 0.25), value: playable)
    }
    
    @ViewBuilder
    private func decidedMark(_ result: MiniResult) -> some View {
        if case .won(let piece) = result, let glyph = skin.glyph(for: piece) {
            Text(glyph)
                .font(.system(size: 52))
                .minimumScaleFactor(0.4)
                .transition(.scale(scale: 0.2).combined(with: .opacity))
        } else {
            decidedShape(result)
        }
    }
    
    @ViewBuilder
    private func decidedShape(_ result: MiniResult) -> some View {
        switch result {
        case .won(.X):
            XMark()
                .stroke(theme.xColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .padding(16)
                .shadow(color: Color.black.opacity(0.3), radius: 0, x: 0, y: 3)
                .transition(.scale(scale: 0.2).combined(with: .opacity))
        case .won:
            Circle()
                .strokeBorder(theme.oColor, lineWidth: 12)
                .padding(14)
                .shadow(color: Color.black.opacity(0.3), radius: 0, x: 0, y: 3)
                .transition(.scale(scale: 0.2).combined(with: .opacity))
        case .draw:
            Image(systemName: "equal")
                .font(.system(size: 30, weight: .black))
                .foregroundColor(Color.white.opacity(0.6))
        case .open:
            EmptyView()
        }
    }
    
    private func cell(_ miniIndex: Int, _ cellIndex: Int, playable: Bool) -> some View {
        let piece = board.piece(board: miniIndex, cell: cellIndex)
        let move = UltimateMove(board: miniIndex, cell: cellIndex)
        let legal = interactive && playable && piece == .E
        let isLast = board.lastMove == move
        
        return ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(LinearGradient(colors: [theme.tileTop, theme.tileBottom], startPoint: .top, endPoint: .bottom))
            
            if isLast {
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(piece == .X ? theme.xColor : theme.oColor, lineWidth: 2)
            }
            
            if hint == move {
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(GamePalette.gold, lineWidth: 3)
                    .pulsing(1.1)
            }
            
            if let glyph = skin.glyph(for: piece) {
                Text(glyph)
                    .font(.system(size: 18))
                    .minimumScaleFactor(0.4)
                    .transition(.scale(scale: 0.1).combined(with: .opacity))
            } else if piece == .X {
                XMark()
                    .stroke(theme.xColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .padding(7)
                    .transition(.scale(scale: 0.1).combined(with: .opacity))
            } else if piece == .O {
                Circle()
                    .strokeBorder(theme.oColor, lineWidth: 4)
                    .padding(5)
                    .transition(.scale(scale: 0.1).combined(with: .opacity))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Rectangle())
        .onTapGesture {
            if legal { onTap(move) }
        }
    }
}
