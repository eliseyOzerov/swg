# swg

Swift Vector Graphics. `swg` is an independent Swift package for parsing and representing SVG documents.

The core package intentionally has no package dependencies. XML parsing uses Foundation's `XMLParser` (`FoundationXML` where that module is split out).

See [TODO.md](TODO.md) for the SVG standard coverage checklist. Items are checked only when covered by focused tests.

## Visual validation

Render-affecting features also have a growing fixture-based visual validation layer. Fixtures live in `Tests/SwgTests/VisualFixtures` as paired SVG and `.golden.txt` pixel maps, and `SVGVisualValidationTests` renders parsed documents through a deterministic CoreGraphics rasterizer before comparing the top-to-bottom visual output.
