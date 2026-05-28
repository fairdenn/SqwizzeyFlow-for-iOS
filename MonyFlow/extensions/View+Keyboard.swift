import SwiftUI
import UIKit

extension View {
    /// Скрывает клавиатуру.
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
