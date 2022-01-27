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
    
    var difficulty: Int
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Group {
                    Text("Win Rate")
                        .font(.title)
                        
                    Text("\(viewModel.formattedWinRate)%")
                        .font(.title)
                        .padding(.bottom, geometry.size.height/200)
                }
                LazyVGrid(columns: column, spacing: 5) {
                    ForEach(0..<9) { i in
                        ZStack {
                            GameCircleView(proxy: geometry)
                            PlayerIndicator(systemImageName: viewModel.gameBoard.position[i].rawValue)
                        }.onTapGesture {
                            viewModel.processGame(i, diffculty: difficulty)
                        }
                    }.alert(item: $viewModel.alertItem, content: { alertItem in
                        Alert(title: alertItem.title,
                              message: alertItem.message,
                              dismissButton: .default(viewModel.alertItem!.buttonTitle))
                    })
                }
                
                HStack {
                    Spacer()
                    Text("Player Win")
                        .font(.title2)
                        .offset(y: 50)
                    Spacer()
                    
                    Text("Computer Win")
                        .font(.title2)
                        .offset(y: 50)
                    Spacer()
                    
                }
                HStack {
                    Spacer()
                    Text("\(viewModel.humanWin)")
                        .offset(x:-25,y: 70)
                        .font(.title)
                        .padding(.bottom, 150)
                    Spacer()
                    
                    
                    Text("\(viewModel.computerWin)")
                        .offset(y: 70)
                        .font(.title)
                        .padding(.bottom, 150)
                    Spacer()
                }
                 Spacer()
            }.disabled(viewModel.isDisabled)
                .padding()
                .alert(item: $viewModel.alertItem, content: { alertItem in
                    Alert(title: alertItem.title,
                          message: alertItem.message,
                          dismissButton: .default(viewModel.alertItem!.buttonTitle, action:  { viewModel.resetGame() } ))
                })
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
        GameView(difficulty: -1)
    }
}

