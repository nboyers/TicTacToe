//
//  ContentView.swift
//  TicTacToe
//
//  Created by Noah Boyers on 6/15/21.
//

import SwiftUI

struct GameView: View {
    
    @StateObject private var viewModel = GameViewModel(position: [.E, .E, .E, .E, .E, .E, .E, .E, .E], turn: .X, lastMove: -1)
    let column: [GridItem] = [GridItem(.flexible()),
                              GridItem(.flexible()),
                              GridItem(.flexible()),]
    
    var body: some View {
        
        GeometryReader { geometry in
            VStack {
                Spacer()
                LazyVGrid(columns: column, spacing: 5) {
                    ForEach(0..<9) { i in
                        ZStack {
                            GameCircleView(proxy: geometry)
                            PlayerIndicator(systemImageName: viewModel.gameBoard.position[i].rawValue)
                        }.onTapGesture {
                            viewModel.processGame(i)
                        }
                    }
                }
                
                Spacer()
            }.disabled(viewModel.isDisabled)
            .padding()
        }
    }
}
struct GameCircleView: View {
    var proxy : GeometryProxy
    var body: some View {
        Circle()
            .foregroundColor(.red).opacity(0.5)
            .frame(width: proxy.size.width/3 - 15,
                   height: proxy.size.width/3 - 15)
    }
}

struct PlayerIndicator: View {
    var systemImageName : String
    var body: some View {
        Image(systemName: systemImageName)
            .resizable()
            .frame(width: 40, height:40)
    }
}


struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        GameView()
    }
}

