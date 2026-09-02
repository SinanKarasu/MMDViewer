# Quick Look for Mathpix Markdown

## Current foundation

MMD Viewer exports `com.sinankarasu.mathpix-markdown` as a text-based Uniform
Type Identifier and registers itself as an editor for `.mmd` files. This Mac
also has an existing `uk.co.mikeosoft.mmd` declaration, so the document entry
accepts both identifiers rather than trying to redefine the pre-existing type.
Installing the app through `make install` registers the declarations with Launch Services.
This enables Finder's **Open With** association and gives Quick Look stable
types to dispatch on. Files resolved to the app-owned type can fall back to a
source-text preview because it conforms to `public.plain-text`. On this Mac,
however, Spotlight currently resolves `.mmd` to `uk.co.mikeosoft.mmd`, whose
registered type tree does not advertise that conformance. A useful preview
therefore should not depend on the generic text fallback.

## Recommended extension

A rendered preview is worthwhile, but it should be a separate macOS Quick Look
Preview Extension embedded in MMD Viewer rather than preview code inside the
application process.

The extension should be data-based:

```text
.mmd URL
   │
   ▼
QLPreviewProvider
   │ reads UTF-8 source and neighboring images
   ▼
shared, non-UI MMD renderer
   │
   ▼
QLPreviewReply(content type: HTML)
```

The extension's `Info.plist` should declare:

- extension point `com.apple.quicklook.preview`;
- `QLIsDataBasedPreview = true`;
- `QLSupportedContentTypes` containing both `com.sinankarasu.mathpix-markdown`
  and `uk.co.mikeosoft.mmd`;
- a `QLPreviewProvider` principal class.

## Refactoring required first

The existing renderer in `MMDWorkbench` is currently coupled to the application's
custom `WKURLSchemeHandler`. Quick Look cannot assume that scheme handler exists.
Before adding the target, extract a public, deterministic rendering component
that can produce HTML without a `WebPage` and inject its assets explicitly.

For the extension, either embed the renderer JavaScript and CSS in the HTML or
provide them as `QLPreviewReply` attachments. Neighboring Mathpix `images/`
resources should become attachments referenced with `cid:` URLs. Do not grant
network access to the extension; previews should remain local and deterministic.

## Suggested delivery order

1. Unit-test the extracted source-to-HTML renderer.
2. Add a macOS Quick Look Preview Extension target to `MMDViewer.xcodeproj`.
3. Return a small HTML preview for a fixture with inline and display mathematics.
4. Add image attachment rewriting and a missing-image placeholder.
5. Verify with `qlmanage -r`, `pluginkit`, and Finder's space-bar preview.
6. Consider a separate Thumbnail Extension only after previews are reliable.

This keeps the installed editor useful now and makes the eventual Quick Look
work a small adapter around shared rendering rather than a second MMD renderer.
