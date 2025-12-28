import SwiftUI

struct DreamPostcardView: View {
    let dreamItem: DreamItem
    let uiImage: UIImage?
    var width: CGFloat = 300 // 默认宽度，可动态调整以生成高清图
    
    private var scale: CGFloat {
        width / 300.0
    }
    
    var body: some View {
        ZStack {
            Color(hex: "FDFBF7") // 米色背景
            
            VStack(spacing: 0) {
                // 1. 图片区域
                if let image = uiImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: width) // 正方形构图
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: width, height: width)
                        .overlay(Image(systemName: "photo").foregroundColor(.gray).font(.system(size: 40 * scale)))
                }
                
                // 2. 文字区域
                VStack(alignment: .leading, spacing: 12 * scale) {
                    HStack {
                        Text(dreamItem.date.formatted(date: .long, time: .omitted))
                            .font(.system(size: 12 * scale, design: .serif))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 12 * scale))
                            .foregroundColor(.purple)
                    }
                    
                    Text("“")
                        .font(.system(size: 28 * scale, design: .serif))
                        .foregroundColor(.purple.opacity(0.6))
                    
                    Text(dreamItem.story.isEmpty ? dreamItem.originalText : dreamItem.story)
                        .font(.system(size: 14 * scale, design: .serif))
                        .lineSpacing(4 * scale)
                        .foregroundColor(.black.opacity(0.8))
                        .lineLimit(6)
                        .multilineTextAlignment(.leading)
                    
                    Spacer(minLength: 0)
                    
                    HStack {
                        Spacer()
                        Text("DreamCatcher · 梦境捕获")
                            .font(.system(size: 10 * scale, weight: .medium))
                            .foregroundColor(.gray.opacity(0.6))
                            .tracking(2 * scale)
                    }
                }
                .padding(20 * scale)
                .frame(width: width, height: width * 2/3) // 保持 3:2 比例
                .background(Color.white)
            }
        }
        .frame(width: width, height: width * 5/3) // 总尺寸 3:5 比例
        .cornerRadius(12 * scale)
        .shadow(radius: 10 * scale)
    }
}
