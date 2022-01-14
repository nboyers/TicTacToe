//
//  Double+Extension.swift
//  TicTacToe
//
//  Created by Noah Boyers on 1/13/22.
//

import Foundation

extension Double {
    func roundToDecimal(_ fractionDigits: Int) -> Double {
        let multiplier = pow(10, Double(fractionDigits))
        return Darwin.round(self * multiplier) / multiplier
    }
}
