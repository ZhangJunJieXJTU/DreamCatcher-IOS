import SwiftUI
import SwiftData

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showHint: Bool = true
    
    var body: some View {
        ZStack {
            // 背景层
            ParticleBackgroundView()
                .ignoresSafeArea()
            
            // 渐变叠加，增强氛围
            RadialGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.black.opacity(0.8)]),
                center: .center,
                startRadius: 50,
                endRadius: 500
            )
            .ignoresSafeArea()
            
            // 全屏点击手势
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if !viewModel.speechManager.isRecording {
                        viewModel.startRecording()
                        withAnimation {
                            showHint = false
                        }
                    } else {
                        viewModel.stopRecording()
                    }
                }
            
            VStack {
                // 顶部标题区
                VStack(spacing: 8) {
                    Text("DreamCatcher")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("在星光中捕捉你的梦境")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.top, 60)
            
            // 输入模式切换
                /*
                Picker("输入模式", selection: $viewModel.inputMode.animation(.easeInOut(duration: 0.3))) {
                    Text("语音").tag(HomeViewModel.InputMode.audio)
                    Text("文字").tag(HomeViewModel.InputMode.text)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 40)
                .padding(.top, 20)
                */
                
                Spacer()
                
                // 中间可视化区
                ZStack {
                    // if viewModel.inputMode == .audio {
                        AudioVisualizerView(audioLevel: viewModel.speechManager.audioLevel)
                        
                        // 显示实时转录文本或计时器
                        if viewModel.speechManager.isRecording {
                            VStack(spacing: 12) {
                                Text(formatDuration(viewModel.recordingDuration))
                                    .font(.system(size: 40, weight: .thin, design: .monospaced))
                                    .foregroundColor(.white)
                                    .transition(.opacity)
                                
                                Text(viewModel.speechManager.transcript)
                                    .font(.title3)
                                    .fontWeight(.light)
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .frame(maxWidth: 300)
                            }
                        } else if showHint {
                            Text("点击任意位置开始录音")
                                .font(.title2)
                                .fontWeight(.light)
                                .foregroundColor(.white.opacity(0.4))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .frame(maxWidth: 300)
                                .transition(.opacity)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        withAnimation(.easeOut(duration: 1.0)) {
                                            showHint = false
                                        }
                                    }
                                }
                        }
                    // } else {
                        // 文字输入界面
                        /*
                        TextInputView(
                            text: $viewModel.textInput,
                            onCommit: {
                                viewModel.confirmDream()
                            },
                            onClear: {
                                viewModel.clearText()
                            }
                        )
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        */
                    // }
                }
                
                Spacer()
                
                // 底部占位，不再显示录音按钮
                Color.clear.frame(height: 100)
            }
        }
        .onTapGesture {
            // 只有在语音模式下才响应全屏点击
            if viewModel.inputMode == .audio {
                if !viewModel.speechManager.isRecording {
                    viewModel.startRecording()
                    withAnimation {
                        showHint = false
                    }
                } else {
                    viewModel.stopRecording()
                }
            } else {
                // 文字模式下点击背景收起键盘
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        // 备注输入弹窗
        .sheet(isPresented: $viewModel.showNoteInput) {
            NoteInputView(text: $viewModel.dreamNote) {
                viewModel.confirmDream()
            }
            .presentationDetents([.fraction(0.3)])
            .presentationDragIndicator(.visible)
        }
        // 处理状态导航
        .sheet(isPresented: $viewModel.isProcessing) {
            if let dreamItem = viewModel.currentDreamItem {
                DreamResultView(
                    dreamItem: dreamItem,
                    onSave: {
                        viewModel.saveDream(context: modelContext)
                    },
                    onShare: {
                        // 实现分享逻辑
                    },
                    onDiscard: {
                        viewModel.discardDream()
                    }
                )
            } else {
                StarTrackView(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
                    .interactiveDismissDisabled() // 禁止手势关闭，强制等待完成
            }
        }
        .alert(isPresented: $viewModel.showErrorAlert) {
            Alert(
                title: Text("连接中断"),
                message: Text(viewModel.errorMessage ?? "未知错误"),
                primaryButton: .default(Text("重试")) {
                    // 重试逻辑
                    Task {
                        await viewModel.processDream()
                    }
                },
                secondaryButton: .cancel(Text("稍后再试")) {
                    viewModel.isProcessing = false
                }
            )
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct NoteInputView: View {
    @Binding var text: String
    var onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("记录梦的注脚")
                .font(.headline)
                .padding(.top)
            
            TextField("在此刻，封存梦的轮廓...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button(action: onConfirm) {
                Text("唤醒梦境")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    HomeView()
        .modelContainer(for: DreamItem.self, inMemory: true)
}
