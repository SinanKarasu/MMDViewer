import AppKit
import QuickLookThumbnailing

final class ThumbnailProvider: QLThumbnailProvider {
    override func provideThumbnail(for request: QLFileThumbnailRequest,
                                   _ handler: @escaping (QLThumbnailReply?, (any Error)?) -> Void) {
        do {
            let file = try FileHandle(forReadingFrom: request.fileURL)
            defer { try? file.close() }
            let data = try file.read(upToCount: 16 * 1024) ?? Data()
            let lines = String(decoding: data, as: UTF8.self).split(whereSeparator: \.isNewline)
            let heading = lines.first { $0.hasPrefix("# ") }.map { String($0.dropFirst(2)) }
            let title = heading ?? request.fileURL.deletingPathExtension().lastPathComponent
            let size = CGSize(width: min(request.maximumSize.width, request.maximumSize.height * 0.76),
                              height: min(request.maximumSize.height, request.maximumSize.width / 0.76))
            handler(QLThumbnailReply(contextSize: size, currentContextDrawing: {
                let page = CGRect(origin: .zero, size: size).insetBy(dx: 2, dy: 2)
                NSColor.white.setFill()
                NSBezierPath(roundedRect: page, xRadius: size.width * 0.07,
                             yRadius: size.width * 0.07).fill()
                let blue = NSColor(srgbRed: 0.06, green: 0.24, blue: 0.87, alpha: 1)
                let glyph = NSAttributedString(string: "∫", attributes: [
                    .font: NSFont.systemFont(ofSize: page.height * 0.56, weight: .semibold),
                    .foregroundColor: blue
                ])
                let glyphSize = glyph.size()
                glyph.draw(at: NSPoint(x: page.midX - glyphSize.width / 2,
                                       y: page.midY - glyphSize.height * 0.44))
                if page.width >= 70 {
                    let paragraph = NSMutableParagraphStyle()
                    paragraph.alignment = .center
                    paragraph.lineBreakMode = .byTruncatingTail
                    NSAttributedString(string: String(title.prefix(120)), attributes: [
                        .font: NSFont.systemFont(ofSize: page.width * 0.11, weight: .semibold),
                        .foregroundColor: NSColor.black,
                        .paragraphStyle: paragraph
                    ]).draw(in: CGRect(x: page.minX + 5, y: page.minY + page.height * 0.08,
                                      width: page.width - 10, height: page.height * 0.15))
                }
                return true
            }), nil)
        } catch {
            handler(nil, error)
        }
    }
}
