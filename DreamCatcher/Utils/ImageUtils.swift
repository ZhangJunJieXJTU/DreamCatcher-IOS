import UIKit

struct ImageUtils {
    static func loadImage(from path: String) -> UIImage? {
        // 1. 尝试直接加载 (如果是完整路径)
        if let image = UIImage(contentsOfFile: path) {
            return image
        }
        
        // 2. 尝试从 URL 路径加载 (如果是 file:// URL 字符串)
        if let url = URL(string: path), url.isFileURL {
            if let image = UIImage(contentsOfFile: url.path) {
                return image
            }
            // 3. 处理沙盒路径变化的情况: 提取文件名并在当前的 Documents 目录查找
            let fileName = url.lastPathComponent
            if let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let currentPath = documentsDir.appendingPathComponent(fileName).path
                if let image = UIImage(contentsOfFile: currentPath) {
                    return image
                }
            }
        }
        
        // 4. 如果 urlString 只是文件名 (例如 "dream_xxx.jpg")
        if !path.contains("/") {
             if let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                 let currentPath = documentsDir.appendingPathComponent(path).path
                 if let image = UIImage(contentsOfFile: currentPath) {
                     return image
                 }
             }
        }
        
        return nil
    }
}
