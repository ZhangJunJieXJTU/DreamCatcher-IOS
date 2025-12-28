import SwiftUI
import SceneKit

struct ParticleBackgroundView: UIViewRepresentable {
    // 使用 Environment 监听场景状态
    @Environment(\.scenePhase) private var scenePhase
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = SCNScene()
        sceneView.backgroundColor = UIColor.black
        // 关键设置：仅在渲染时播放，允许系统暂停
        sceneView.isPlaying = true
        sceneView.preferredFramesPerSecond = 30 // 降低帧率以省电
        
        // 创建相机
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 10)
        sceneView.scene?.rootNode.addChildNode(cameraNode)
        
        // 创建粒子系统
        let particleSystem = SCNParticleSystem()
        particleSystem.birthRate = 100 // 每秒生成数量
        particleSystem.particleLifeSpan = 5 // 粒子生命周期
        particleSystem.particleLifeSpanVariation = 2
        particleSystem.particleSize = 0.1
        particleSystem.particleColor = .white
        particleSystem.emitterShape = SCNSphere(radius: 5)
        particleSystem.spreadingAngle = 0
        particleSystem.speedFactor = 0.5
        
        // 简单的星空效果，使用圆形图片纹理
        particleSystem.particleImage = createCircleImage()
        
        // 粒子运动
        particleSystem.acceleration = SCNVector3(0, 0, 2) // 向相机移动
        
        let particlesNode = SCNNode()
        particlesNode.addParticleSystem(particleSystem)
        sceneView.scene?.rootNode.addChildNode(particlesNode)
        
        // 添加一个旋转动画让背景更有动感
        let action = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 0, z: 1, duration: 20))
        particlesNode.runAction(action)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // 根据场景状态暂停或恢复渲染
        switch scenePhase {
        case .active:
            uiView.isPlaying = true
        case .background, .inactive:
            uiView.isPlaying = false
        @unknown default:
            uiView.isPlaying = false
        }
    }
    
    // 生成圆形图片
    private func createCircleImage() -> UIImage {
        let size = CGSize(width: 32, height: 32)
        return UIGraphicsImageRenderer(size: size).image { context in
            UIColor.white.setFill()
            let rect = CGRect(origin: .zero, size: size)
            UIBezierPath(ovalIn: rect).fill()
        }
    }
}

#Preview {
    ParticleBackgroundView()
        .ignoresSafeArea()
}
