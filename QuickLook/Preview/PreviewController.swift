import Foundation
import JavaScriptCore
import Quartz
import UniformTypeIdentifiers

final class PreviewController: QLPreviewProvider, QLPreviewingController {
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let url = request.fileURL
        return QLPreviewReply(dataOfContentType: .html, contentSize: CGSize(width: 820, height: 720)) { reply in
            let preview = try Self.render(url: url)
            reply.stringEncoding = .utf8
            reply.attachments = preview.attachments
            return Data(preview.html.utf8)
        }
    }

    static func render(url: URL) throws -> (html: String, attachments: [String: QLPreviewReplyAttachment]) {
        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }
        let limit = 64 * 1024
        let data = try file.read(upToCount: limit + 1) ?? Data()
        let isExcerpt = data.count > limit
        let prefix = data.prefix(limit)
        let excerpt = isExcerpt ? (prefix.lastIndex(of: 10).map { prefix.prefix(upTo: $0) } ?? prefix) : prefix
        let source = String(decoding: excerpt, as: UTF8.self)
        let rendered = try renderMarkdown(source)
        let images = attachImages(in: rendered, relativeTo: url)
        let notice = isExcerpt ? "<p><em>Showing the start of this document. Open in MMDViewer to read the full file.</em></p>" : ""
        return ("""
        <!doctype html><html><head><meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; img-src cid: data:; base-uri 'none'; form-action 'none'">
        <style>
        :root { color-scheme: light dark; }
        body { font: 16px/1.55 system-ui; margin: 32px auto; padding: 0 28px; max-width: 840px; }
        /* Mathpix emits plain paragraphs as unclassed divs. */
        #setText > div:not([class], [id]) + div:not([class], [id]) { margin-top: 0.75em; }
        img { max-width: 100%; height: auto; } pre { overflow: auto; }
        table { border-collapse: collapse; } td, th { border: 1px solid GrayText; padding: .3em .6em; }
        </style></head><body>\(notice)\(images.html)</body></html>
        """, images.attachments)
    }

    private static func renderMarkdown(_ source: String) throws -> String {
        let extensionBundle = Bundle(for: Self.self)
        guard let bundleURL = extensionBundle.resourceURL?.appendingPathComponent("MMDWorkbench_MMDWorkbench.bundle"),
              let rendererURL = Bundle(url: bundleURL)?.url(forResource: "mathpix-markdown-it", withExtension: "js"),
              let context = JSContext()
        else { throw CocoaError(.fileNoSuchFile) }

        // The browser bundle registers timer hooks during initialization. Static
        // previews render synchronously and never run those callbacks.
        context.evaluateScript("var window = {}; var setTimeout = () => 0; var clearTimeout = () => {}; var setInterval = setTimeout; var clearInterval = clearTimeout;")
        context.evaluateScript(try String(contentsOf: rendererURL, encoding: .utf8), withSourceURL: rendererURL)
        guard let renderer = context.evaluateScript("window.render"), !renderer.isUndefined,
              let result = renderer.call(withArguments: [source, ["htmlTags": false, "breaks": false]]),
              result.isString, let html = result.toString()
        else {
            let detail = context.exception?.toString() ?? "The Mathpix renderer did not return HTML."
            throw NSError(domain: "MMDQuickLook", code: 1, userInfo: [NSLocalizedDescriptionKey: detail])
        }
        return html
    }

    private static func attachImages(in rendered: String, relativeTo url: URL)
        -> (html: String, attachments: [String: QLPreviewReplyAttachment]) {
        let root = url.deletingLastPathComponent().resolvingSymlinksInPath()
            .appendingPathComponent("images").standardizedFileURL
        guard let pattern = try? NSRegularExpression(pattern: #"<img\b[^>]*?\ssrc="((?:\./)?images/[^"]+)"[^>]*>"#)
        else { return (rendered, [:]) }
        let matches = pattern.matches(in: rendered, range: NSRange(rendered.startIndex..., in: rendered))
        var html = rendered as NSString
        var attachments: [String: QLPreviewReplyAttachment] = [:]
        var budget = 12 * 1024 * 1024
        for match in matches.reversed() {
            let path = html.substring(with: match.range(at: 1))
            let relative = path.hasPrefix("./") ? String(path.dropFirst(2)) : path
            let filename = String(relative.dropFirst("images/".count))
                .replacingOccurrences(of: "&amp;", with: "&").removingPercentEncoding
            guard let filename,
                  let attachment = readImage(filename: filename, root: root, budget: budget) else {
                html = html.replacingCharacters(in: match.range,
                    with: "<em>Image unavailable in Quick Look</em>") as NSString
                continue
            }
            let identifier = "image-\(attachments.count)"
            attachments[identifier] = attachment
            budget -= attachment.data.count
            html = html.replacingCharacters(in: match.range(at: 1), with: "cid:" + identifier) as NSString
        }
        return (html as String, attachments)
    }

    private static func readImage(filename: String, root: URL, budget: Int) -> QLPreviewReplyAttachment? {
        let image = root.appendingPathComponent(filename).resolvingSymlinksInPath().standardizedFileURL
        guard image.path.hasPrefix(root.path + "/"), budget > 0,
              let type = UTType(filenameExtension: image.pathExtension),
              [UTType.png, .jpeg, .gif, .webP].contains(type),
              let handle = try? FileHandle(forReadingFrom: image) else { return nil }
        defer { try? handle.close() }
        let limit = min(budget, 4 * 1024 * 1024)
        guard let data = try? handle.read(upToCount: limit + 1), !data.isEmpty, data.count <= limit else { return nil }
        return QLPreviewReplyAttachment(data: data, contentType: type)
    }
}
