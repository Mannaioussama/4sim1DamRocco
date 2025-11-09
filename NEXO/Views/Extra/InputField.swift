//
//  InputField.swift
//  NEXO
//
//  Created by ROCCO 4X on 4/11/2025.
//

import SwiftUI  // ← This line is required

struct InputField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(Color(UIColor.systemGray6)) // light gray background
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .font(.system(size: 16))
            .foregroundColor(.primary)
    }
}

// MARK: - Preview
struct InputField_Previews: PreviewProvider {
    static var previews: some View {
        InputField(placeholder: "Placeholder text", text: .constant(""))
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
