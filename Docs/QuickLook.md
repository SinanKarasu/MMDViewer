# Quick Look for Mathpix Markdown

MMDViewer embeds two macOS extensions. Both recognize the app's
`com.sinankarasu.mathpix-markdown` type and the existing
`uk.co.mikeosoft.mmd` type used by some installations.

- **Preview** renders Mathpix Markdown to static HTML using the same
  offline JavaScript bundle as MMDWorkbench. Large documents show an excerpt.
  Network requests and document HTML
  are disabled. The extension attempts to load raster images under the sibling
  `images/` folder when macOS grants access. If the folder is unavailable to
  Quick Look, open the export folder in MMDViewer to see its images.
- **Thumbnail** draws a small page with a blue integral. At larger thumbnail
  sizes it adds the first Markdown title or the filename. It reads only the
  beginning of the document and does not start WebKit.

Build and install the macOS app, then select an `.mmd` document in Finder and
press Space. For thumbnails, use Icon View and enable **Show icon preview** in
Finder's View Options. The test corpus includes standalone documents and Mathpix
exports with sibling `images/` directories. If Finder shows an older result,
try a fresh copy with a new filename.

The extensions are embedded only in the macOS build.
