import SwiftUI

enum AppFonts {
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title = Font.system(size: 28, weight: .semibold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
    
    static let moneyLarge = Font.system(size: 32, weight: .bold, design: .rounded).monospacedDigit()
    static let moneyMedium = Font.system(size: 20, weight: .semibold, design: .rounded).monospacedDigit()
    static let moneySmall = Font.system(size: 16, weight: .medium, design: .rounded).monospacedDigit()
    
    static let body = Font.system(size: 17, weight: .regular)
    static let bodyBold = Font.system(size: 17, weight: .semibold)
    static let caption = Font.system(size: 13, weight: .regular)
}
