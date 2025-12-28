import SwiftUI

struct TextInputView: View {
    @Binding var text: String
    var onCommit: () -> Void
    var onClear: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var showClearConfirmation = false
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .center) { // 改为居中对齐
                // 背景
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.inputBackground.opacity(0.3)) // 使用 extension 中定义的颜色
                    .frame(minHeight: 50) // 减小高度为 50
                
                if text.isEmpty {
                    Text("在此输入梦境内容...")
                        .foregroundColor(.gray)
                        .padding(12)
                }
                
                TextField("", text: $text, axis: .vertical) // 使用 TextField 支持 axis: .vertical
                    .font(.system(size: 16))
                    .foregroundColor(.white) // 白色字体
                    .multilineTextAlignment(.center) // 文字居中
                    .padding(12)
                    .frame(minHeight: 50) // 减小高度为 50
                    .focused($isFocused)
                    .submitLabel(.send) // 将回车键变为发送
                    .onSubmit {
                        // 回车发送
                        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !text.isEmpty {
                            isFocused = false
                            onCommit()
                        }
                    }
                    .onChange(of: text) {
                        // 基础校验：去除首尾空格（仅在提交时严格处理，这里可以做实时过滤非法字符如果需要）
                        // 简单的非法字符过滤示例：只过滤掉除换行符以外的控制字符
                        let filtered = text.filter { char in
                            for scalar in char.unicodeScalars {
                                if CharacterSet.controlCharacters.contains(scalar) && scalar != "\n" {
                                    return false
                                }
                            }
                            return true
                        }
                        
                        if filtered != text {
                            text = filtered
                        }
                    }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            
            // 底部工具栏
            HStack {
                // 字数统计
                Text("\(text.count) 字")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // 清空按钮
                if !text.isEmpty {
                    Button(action: {
                        showClearConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .confirmationDialog("确定要清空内容吗？", isPresented: $showClearConfirmation, titleVisibility: .visible) {
                        Button("清空", role: .destructive) {
                            onClear()
                        }
                        Button("取消", role: .cancel) {}
                    }
                }
                
                // 提交按钮 (仅在有内容时可用)
                Button(action: {
                    // 去除首尾空格
                    text = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !text.isEmpty {
                        isFocused = false
                        onCommit()
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .purple)
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
    }
}

// 颜色适配 helper
extension Color {
    static let inputBackground = Color(UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor.secondarySystemBackground : UIColor(hexString: "#F8F9FA")
    })
}

extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
