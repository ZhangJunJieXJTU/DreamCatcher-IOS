import SwiftUI

struct StarTrackView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Star Track Loader
                ZStack {
                    // 外环
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            AngularGradient(gradient: Gradient(colors: [.purple, .clear]), center: .center),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                        .animation(Animation.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)
                    
                    // 内环 (反向旋转)
                    Circle()
                        .trim(from: 0, to: 0.6)
                        .stroke(
                            AngularGradient(gradient: Gradient(colors: [.blue, .clear]), center: .center),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(Angle(degrees: isAnimating ? -360 : 0))
                        .animation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
                    
                    // 中心文字
                    Text("解构星辰...")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.purple)
                        .opacity(isAnimating ? 1.0 : 0.5)
                        .animation(Animation.easeInOut(duration: 0.8).repeatForever(), value: isAnimating)
                }
                .padding(.bottom, 60)
                
                // 状态列表
                VStack(alignment: .leading, spacing: 16) {
                    // 步骤 1: 录音转录完成 (进入处理页面即视为完成)
                    StatusRow(text: "梦呓已捕获", isActive: true, isCompleted: true, color: .green)
                    
                    // 步骤 2: 优化 Prompt
                    StatusRow(
                        text: "正在凝视深渊...",
                        isActive: viewModel.processingStep == .optimizing || viewModel.processingStep == .generating || viewModel.processingStep == .completed,
                        isCompleted: viewModel.processingStep == .generating || viewModel.processingStep == .completed,
                        color: .purple
                    )
                    
                    // 步骤 3: 生成图片与分析
                    StatusRow(
                        text: "重构梦境碎片",
                        isActive: viewModel.processingStep == .generating || viewModel.processingStep == .completed,
                        isCompleted: viewModel.processingStep == .completed,
                        color: .blue
                    )
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct StatusRow: View {
    let text: String
    let isActive: Bool
    let isCompleted: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isActive ? color : Color.gray.opacity(0.3))
                .frame(width: 8, height: 8)
                .shadow(color: isActive ? color : .clear, radius: 4)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(isActive ? color : .gray)
                .opacity(isActive ? 1.0 : 0.5)
            
            if isActive && !isCompleted {
                Spacer()
                ProgressView()
                    .scaleEffect(0.5)
                    .tint(color)
            } else if isCompleted {
                Spacer()
                Image(systemName: "checkmark")
                    .font(.caption)
                    .foregroundColor(color)
            }
        }
    }
}

#Preview {
    StarTrackView(viewModel: HomeViewModel())
}
