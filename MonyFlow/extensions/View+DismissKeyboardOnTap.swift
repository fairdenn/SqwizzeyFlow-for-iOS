import SwiftUI

extension View {
    /// Добавляет жест: любой тап вне поля ввода скрывает клавиатуру.
    /// Использовать на корневом View экрана.
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }
}
