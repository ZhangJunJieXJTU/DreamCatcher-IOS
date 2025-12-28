import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selection = 0
    
    init() {
        // 隐藏原生 TabBar
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 主内容区
            TabView(selection: $selection) {
                HomeView()
                    .tag(0)
                    .ignoresSafeArea() // 确保背景铺满
                
                CalendarView()
                    .tag(1)
                
                GalleryView()
                    .tag(2)
            }
            
            // 自定义玻璃拟态 TabBar
            HStack {
                Spacer()
                TabBarItem(icon: "mic.fill", text: "记录", isSelected: selection == 0) {
                    selection = 0
                }
                Spacer()
                TabBarItem(icon: "calendar", text: "日历", isSelected: selection == 1) {
                    selection = 1
                }
                Spacer()
                TabBarItem(icon: "photo.on.rectangle", text: "画廊", isSelected: selection == 2) {
                    selection = 2
                }
                Spacer()
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
            .background(.ultraThinMaterial)
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.white.opacity(0.1)),
                alignment: .top
            )
        }
        .ignoresSafeArea(.keyboard) // 避免键盘顶起 TabBar
    }
}

struct TabBarItem: View {
    let icon: String
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(text)
                    .font(.system(size: 10))
            }
            .foregroundColor(isSelected ? .purple : .gray)
            .frame(width: 60)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DreamItem.self, inMemory: true)
}
