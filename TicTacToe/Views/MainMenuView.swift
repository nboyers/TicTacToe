//
//  MainMenuView.swift
//  TicTacToe
//
//  Created by Noah Boyers on 12/10/21.
//

import SwiftUI




struct MainMenuView: View {
    @State private var maxWidth: CGFloat = .zero
    var body: some View {
        NavigationView {
            VStack {
                
                Spacer()
                Group {
                    NavigationLink("Easy", destination:
                                    GameView(difficulty: 0))
                    NavigationLink("Medium", destination:
                                    GameView(difficulty: 1))
                    NavigationLink("Hard", destination:
                                    GameView(difficulty: 3))
                    NavigationLink("Impossible", destination:
                                    GameView(difficulty: 3))
                }
                .frame(minWidth: 0, maxWidth: 300, minHeight: 0, maxHeight: 100)
                .font(.largeTitle)
                .foregroundColor(.primary)
                .background(RoundedRectangle(cornerRadius: 20)
                                .style(
                                    withStroke: Color.white,
                                    lineWidth: 0,
                                    fill: Color.teal
                                ))
                Spacer()
                
            }
        }
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
    }
}
