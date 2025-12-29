import SwiftUI

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Group {
                switch item.type {
                case .text:
                    Image(systemName: "doc.text")
                        .font(.title2)
                        .foregroundColor(.blue)
                case .image(let nsImage):
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .cornerRadius(4)
                }
            }
            .frame(width: 40, height: 40)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.preview)
                    .lineLimit(2)
                    .font(.body)
                    .truncationMode(.tail)
                
                Text(item.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(8)
    }
}
