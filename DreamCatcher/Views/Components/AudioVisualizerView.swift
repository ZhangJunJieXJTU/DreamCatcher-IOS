import SwiftUI

struct AudioVisualizerView: View {
    var audioLevel: Float // 0.0 - 1.0
    
    var body: some View {
        ZStack {
            // 基础光晕
            Circle()
                .fill(Color.purple.opacity(0.2))
                .frame(width: 200, height: 200)
                .blur(radius: 20)
                .scaleEffect(1.0 + CGFloat(audioLevel) * 0.5)
                .animation(.linear(duration: 0.1), value: audioLevel)
            
            // 核心圆环
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                .frame(width: 180, height: 180)
            
            // 动态波纹 (模拟)
            ForEach(0..<3) { i in
                Circle()
                    .stroke(Color.white.opacity(Double(3-i) * 0.2), lineWidth: 2)
                    .frame(width: 100, height: 100)
                    .scaleEffect(1.0 + CGFloat(audioLevel) * CGFloat(i+1) * 0.3)
                    .opacity(1.0 - Double(audioLevel) * 0.5)
                    .animation(.easeOut(duration: 0.2).delay(Double(i) * 0.05), value: audioLevel)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        AudioVisualizerView(audioLevel: 0.5)
    }
}
