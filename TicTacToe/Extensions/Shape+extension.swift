//
//  Shape+extension.swift
//  TicTacToe
//
//  Created by Noah Boyers on 12/29/21.
//

import SwiftUI

extension Shape {
    func style<S: ShapeStyle, F: ShapeStyle>(
        withStroke strokeContent: S,
        lineWidth: CGFloat = 1,
        fill fillContent: F
    ) -> some View {
        self.stroke(strokeContent, lineWidth: lineWidth)
    .background(fill(fillContent))
    }
}
