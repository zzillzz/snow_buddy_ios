//
//  OTPCodeInputView.swift
//  snow-buddy
//
//  Created by Claude Code
//

import SwiftUI

struct OTPCodeInputView: View {
    @Binding var code: String
    @FocusState private var focusedField: Int?
    @State private var digits: [String] = Array(repeating: "", count: 6)

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<6, id: \.self) { index in
                SingleDigitTextField(
                    text: $digits[index],
                    isFocused: focusedField == index,
                    onTextChange: { newValue in
                        handleTextChange(at: index, newValue: newValue)
                    },
                    onDelete: {
                        handleDelete(at: index)
                    }
                )
                .focused($focusedField, equals: index)
            }
        }
        .onAppear {
            focusedField = 0
        }
        .onChange(of: digits) { oldValue, newValue in
            code = newValue.joined()
        }
    }

    private func handleTextChange(at index: Int, newValue: String) {
        guard !newValue.isEmpty else {
            return
        }

        // If user pastes multiple digits, distribute them
        if newValue.count > 1 {
            handlePaste(newValue)
            return
        }

        // User entered single digit, focus next
        if index < 5 {
            focusedField = index + 1
        } else {
            // Last field, dismiss keyboard
            focusedField = nil
        }
    }

    private func handleDelete(at index: Int) {
        // Focus previous field on delete
        if index > 0 {
            focusedField = index - 1
        }
    }

    private func handlePaste(_ pastedText: String) {
        let cleaned = pastedText.filter { $0.isNumber }

        if cleaned.count == 6 {
            for (index, char) in cleaned.enumerated() {
                digits[index] = String(char)
            }
            focusedField = nil // Dismiss keyboard
        }
    }
}

struct SingleDigitTextField: View {
    @Binding var text: String
    var isFocused: Bool
    var onTextChange: (String) -> Void
    var onDelete: () -> Void

    var body: some View {
        TextField("", text: $text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .frame(width: 45, height: 55)
            .background(isFocused ? Color("TextFieldBackground") : Color.gray.opacity(0.2))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("PrimaryColor"), lineWidth: isFocused ? 2 : 1)
            )
            .lexendFont(.bold, size: 24)
            .onChange(of: text) { oldValue, newValue in
                // Handle deletion
                if newValue.isEmpty && !oldValue.isEmpty {
                    onDelete()
                    return
                }

                // Limit to 1 digit and only numbers
                let filtered = newValue.filter { $0.isNumber }
                if filtered.count > 1 {
                    text = String(filtered.prefix(1))
                } else if filtered != newValue {
                    text = filtered
                }

                onTextChange(text)
            }
            .animation(.easeIn(duration: 0.1), value: isFocused)
    }
}

#Preview {
    VStack(spacing: 40) {
        Text("Empty State")
            .lexendFont(.bold, size: 18)
        OTPCodeInputView(code: .constant(""))
            .padding()

        Text("Filled State")
            .lexendFont(.bold, size: 18)
        OTPCodeInputView(code: .constant("123456"))
            .padding()
    }
    .appBackground()
}
