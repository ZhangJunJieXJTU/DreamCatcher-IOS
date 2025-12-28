import SwiftUI

struct UniversalImageView: View {
    let urlString: String
    
    var body: some View {
        Group {
            if let uiImage = loadImage() {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if let url = URL(string: urlString), url.scheme == "http" || url.scheme == "https" {
                // 网络图片
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        placeholder
                    }
                }
            } else {
                // 加载失败或文件不存在
                placeholder
            }
        }
    }
    
    var placeholder: some View {
        ZStack {
            Color.gray.opacity(0.1)
            Image(systemName: "photo")
                .foregroundColor(.gray.opacity(0.5))
        }
    }
    
    private func loadImage() -> UIImage? {
        return ImageUtils.loadImage(from: urlString)
    }
}
