import CoreGraphics
import Foundation
import SwiftUI

/// A SwiftUI view that renders an `SVGDocument` with the package's native path renderer.
public struct SVG: View {
	@Binding private var boundDocument: SVGDocument?
	@State private var loadedDocument: SVGDocument?
	@State private var loadedSourceID: String?

	private var initialDocument: SVGDocument?
	private var usesBoundDocument: Bool
	private var loadSource: SVGLoadSource?

	/// Rendering and layout options applied to the document.
	public var options: SVGRenderOptions

	/// The parsed SVG document this view renders when one is available.
	public var document: SVGDocument? {
		usesBoundDocument ? boundDocument : initialDocument
	}

	/// Creates a SwiftUI SVG view from a parsed document.
	///
	/// - Parameters:
	///   - document: The parsed SVG document to display.
	///   - options: Rendering and layout options for the root drawing pass.
	public init(_ document: SVGDocument, options: SVGRenderOptions = SVGRenderOptions()) {
		self.init(initialDocument: document, boundDocument: nil, loadSource: nil, options: options)
	}

	/// Creates a SwiftUI SVG view backed by a mutable optional document binding.
	///
	/// Use this initializer when the document may be loaded later, or when callers want to modify the parsed document after the view appears.
	///
	/// - Parameters:
	///   - document: A binding to the document the view should render.
	///   - options: Rendering and layout options for the root drawing pass.
	public init(_ document: Binding<SVGDocument?>, options: SVGRenderOptions = SVGRenderOptions()) {
		self.init(initialDocument: nil, boundDocument: document, loadSource: nil, options: options)
	}

	/// Creates a SwiftUI SVG view backed by a mutable document binding.
	///
	/// - Parameters:
	///   - document: A binding to the document the view should render.
	///   - options: Rendering and layout options for the root drawing pass.
	public init(_ document: Binding<SVGDocument>, options: SVGRenderOptions = SVGRenderOptions()) {
		self.init(Binding<SVGDocument?>(
			get: { document.wrappedValue },
			set: { newValue in
				if let newValue {
					document.wrappedValue = newValue
				}
			}
		), options: options)
	}

	/// Parses SVG source and creates a SwiftUI SVG view when parsing succeeds.
	///
	/// - Parameters:
	///   - source: The SVG XML source string to parse.
	///   - parser: The parser configuration to use.
	///   - options: Rendering and layout options for the root drawing pass.
	public init?(source: String, parser: SVGParser = SVGParser(), options: SVGRenderOptions = SVGRenderOptions()) {
		guard let document = parser.parse(source) else { return nil }
		self.init(document, options: options)
	}

	/// Creates a SwiftUI SVG view that loads SVG XML from a bundled resource path.
	///
	/// This mirrors SwiftUI's `Image` initializer for the common bundled-asset case. Pass `"checkmark"` for `checkmark.svg`, or a relative path such as `"Icons/checkmark.svg"` for a resource in a bundle subdirectory.
	///
	/// - Parameters:
	///   - assetPath: The bundled SVG resource name or relative path.
	///   - bundle: The bundle that contains the SVG resource.
	///   - document: An optional binding that receives the parsed document after loading.
	///   - options: Rendering and layout options for the root drawing pass.
	public init(_ assetPath: String, bundle: Bundle = .main, document: Binding<SVGDocument?>? = nil, options: SVGRenderOptions = SVGRenderOptions()) {
		let url = SVGBundleResource.url(for: assetPath, in: bundle)
		self.init(initialDocument: nil, boundDocument: document, loadSource: url.map(SVGLoadSource.file), options: options)
	}

	/// Creates a SwiftUI SVG view that loads SVG XML from a network URL.
	///
	/// - Parameters:
	///   - url: The remote URL to load with `URLSession`.
	///   - document: An optional binding that receives the parsed document after loading.
	///   - options: Rendering and layout options for the root drawing pass.
	public init(url: URL, document: Binding<SVGDocument?>? = nil, options: SVGRenderOptions = SVGRenderOptions()) {
		self.init(initialDocument: nil, boundDocument: document, loadSource: .url(url), options: options)
	}

	/// Creates a SwiftUI SVG view that loads SVG XML from a bundled resource.
	///
	/// - Parameters:
	///   - name: The resource name in `bundle`.
	///   - bundle: The bundle that contains the SVG resource.
	///   - fileExtension: The resource extension, usually `"svg"`.
	///   - subdirectory: An optional bundle subdirectory.
	///   - document: An optional binding that receives the parsed document after loading.
	///   - options: Rendering and layout options for the root drawing pass.
	public init(asset name: String, bundle: Bundle = .main, fileExtension: String? = "svg", subdirectory: String? = nil, document: Binding<SVGDocument?>? = nil, options: SVGRenderOptions = SVGRenderOptions()) {
		let url = bundle.url(forResource: name, withExtension: fileExtension, subdirectory: subdirectory)
			?? bundle.url(forResource: name, withExtension: fileExtension)
		self.init(initialDocument: nil, boundDocument: document, loadSource: url.map(SVGLoadSource.file), options: options)
	}

	/// Creates a SwiftUI SVG view that loads SVG XML from a file URL.
	///
	/// - Parameters:
	///   - url: The file URL for an SVG stored in the app's filesystem.
	///   - document: An optional binding that receives the parsed document after loading.
	///   - options: Rendering and layout options for the root drawing pass.
	public init(file url: URL, document: Binding<SVGDocument?>? = nil, options: SVGRenderOptions = SVGRenderOptions()) {
		self.init(initialDocument: nil, boundDocument: document, loadSource: .file(url), options: options)
	}

	/// Creates a SwiftUI SVG view that loads SVG XML from a filesystem path.
	///
	/// - Parameters:
	///   - path: The path for an SVG stored in the app's filesystem.
	///   - document: An optional binding that receives the parsed document after loading.
	///   - options: Rendering and layout options for the root drawing pass.
	public init(file path: String, document: Binding<SVGDocument?>? = nil, options: SVGRenderOptions = SVGRenderOptions()) {
		self.init(file: URL(fileURLWithPath: path), document: document, options: options)
	}

	/// The SwiftUI body that renders the document into a `Canvas`.
	public var body: some View {
		Group {
			if let renderDocument {
				render(renderDocument)
			} else {
				SwiftUI.Color.clear
			}
		}
		.task(id: loadTaskID) {
			await loadSourceIfNeeded()
		}
	}

	private init(initialDocument: SVGDocument?, boundDocument: Binding<SVGDocument?>?, loadSource: SVGLoadSource?, options: SVGRenderOptions) {
		if let boundDocument {
			_boundDocument = boundDocument
			usesBoundDocument = true
		} else {
			_boundDocument = .constant(nil)
			usesBoundDocument = false
		}
		_loadedDocument = State(initialValue: initialDocument)
		_loadedSourceID = State(initialValue: nil)
		self.initialDocument = initialDocument
		self.loadSource = loadSource
		self.options = options
	}

	private var loadTaskID: String {
		"\(loadSource?.id ?? "none"):\(renderDocument == nil)"
	}

	private var renderDocument: SVGDocument? {
		usesBoundDocument ? boundDocument : loadedDocument ?? initialDocument
	}

	@ViewBuilder private func render(_ document: SVGDocument) -> some View {
		Canvas { context, size in
			let renderer = SVGCanvasRenderer(document: document, size: size, options: options)
			renderer.render(in: &context)
		}
		.aspectRatio(document.viewBox.aspectRatio, contentMode: options.contentMode)
	}

	@MainActor private func loadSourceIfNeeded() async {
		guard let loadSource else { return }
		guard renderDocument == nil || loadedSourceID != loadSource.id else { return }
		guard let document = try? await SVGDocumentLoader.load(from: loadSource) else { return }
		if usesBoundDocument {
			boundDocument = document
		} else {
			loadedDocument = document
		}
		loadedSourceID = loadSource.id
	}
}

/// Controls how `SVG` maps a parsed document into SwiftUI layout and drawing.
public struct SVGRenderOptions {
	/// The SwiftUI content mode used when the view proposes the document aspect ratio.
	public var contentMode: ContentMode
	/// An optional override for the root document's `preserveAspectRatio` mapping.
	public var preserveAspectRatio: SVGPreserveAspectRatio?
	/// A root opacity multiplier applied to all rendered content.
	public var opacity: Double

	/// Creates rendering options for `SVG`.
	///
	/// - Parameters:
	///   - contentMode: The SwiftUI content mode used for aspect-ratio layout.
	///   - preserveAspectRatio: A root `preserveAspectRatio` override, or `nil` to use the parsed document value.
	///   - opacity: A root opacity multiplier applied to rendered content.
	public init(contentMode: ContentMode = .fit, preserveAspectRatio: SVGPreserveAspectRatio? = nil, opacity: Double = 1) {
		self.contentMode = contentMode
		self.preserveAspectRatio = preserveAspectRatio
		self.opacity = opacity
	}
}

enum SVGLoadSource: Equatable {
	case url(URL)
	case file(URL)

	var id: String {
		switch self {
		case .url(let url):
			return "url:\(url.absoluteString)"
		case .file(let url):
			return "file:\(url.path)"
		}
	}
}

enum SVGDocumentLoader {
	static func load(from source: SVGLoadSource) async throws -> SVGDocument? {
		let data: Data
		switch source {
		case .url(let url):
			let response: URLResponse
			(data, response) = try await URLSession.shared.data(from: url)
			if let response = response as? HTTPURLResponse, !(200..<300).contains(response.statusCode) {
				return nil
			}
		case .file(let url):
			data = try Data(contentsOf: url)
		}
		return SVGParser().parse(data)
	}
}

enum SVGBundleResource {
	static func url(for path: String, in bundle: Bundle) -> URL? {
		let filePath = path as NSString
		let fileExtension = filePath.pathExtension.isEmpty ? "svg" : filePath.pathExtension
		let pathWithoutExtension = filePath.pathExtension.isEmpty ? path : filePath.deletingPathExtension
		let resourcePath = pathWithoutExtension as NSString
		let name = resourcePath.lastPathComponent
		let directory = resourcePath.deletingLastPathComponent
		let subdirectory = directory.isEmpty || directory == "." ? nil : directory

		return bundle.url(forResource: name, withExtension: fileExtension, subdirectory: subdirectory)
			?? bundle.url(forResource: pathWithoutExtension, withExtension: fileExtension)
			?? bundle.url(forResource: name, withExtension: fileExtension)
			?? bundle.url(forResource: path, withExtension: nil)
	}
}

private struct SVGCanvasRenderer {
	var document: SVGDocument
	var size: CGSize
	var options: SVGRenderOptions

	func render(in context: inout GraphicsContext) {
		guard size.width > 0, size.height > 0 else { return }
		guard let transform = (options.preserveAspectRatio ?? document.preserveAspectRatio).viewBoxTransform(
			from: document.viewBox,
			to: Rect(x: 0, y: 0, width: size.width, height: size.height)
		) else { return }

		context.drawLayer { layer in
			layer.concatenate(transform.cgAffineTransform)
			for element in document.elements {
				render(element, opacity: options.opacity, in: &layer)
			}
		}
	}

	private func render(_ element: SVGElement, opacity: Double, in context: inout GraphicsContext) {
		switch element {
		case .path(let data):
			render(path: data.path.cgPath, attributes: data.attributes, inheritedOpacity: opacity, forceStroke: false, in: &context)
		case .rect(let data):
			render(path: data.path.cgPath, attributes: data.attributes, inheritedOpacity: opacity, forceStroke: false, in: &context)
		case .circle(let data):
			render(path: data.path.cgPath, attributes: data.attributes, inheritedOpacity: opacity, forceStroke: false, in: &context)
		case .ellipse(let data):
			render(path: data.path.cgPath, attributes: data.attributes, inheritedOpacity: opacity, forceStroke: false, in: &context)
		case .line(let data):
			render(path: data.path.cgPath, attributes: data.attributes, inheritedOpacity: opacity, forceStroke: true, in: &context)
		case .polygon(let data):
			render(path: data.path.cgPath, attributes: data.attributes, inheritedOpacity: opacity, forceStroke: false, in: &context)
		case .polyline(let data):
			render(path: data.path.cgPath, attributes: data.attributes, inheritedOpacity: opacity, forceStroke: true, in: &context)
		case .group(let data):
			render(children: data.children, attributes: data.attributes, inheritedOpacity: opacity, in: &context)
		case .switch(let data):
			render(children: data.children, attributes: data.attributes, inheritedOpacity: opacity, in: &context)
		case .link(let data):
			render(children: data.children, attributes: data.attributes, inheritedOpacity: opacity, in: &context)
		case .svg(let data):
			render(viewport: data, inheritedOpacity: opacity, in: &context)
		case .unknown(let data):
			render(children: data.children, attributes: data.attributes, inheritedOpacity: opacity, in: &context)
		case .foreignObject(let data):
			render(children: data.children, attributes: data.attributes, inheritedOpacity: opacity, in: &context)
		case .use(let data):
			render(use: data, inheritedOpacity: opacity, in: &context)
		case .image, .text:
			break
		}
	}

	private func render(children: [SVGElement], attributes: SVGPaintAttributes, inheritedOpacity: Double, in context: inout GraphicsContext) {
		guard attributes.canRender else { return }
		context.drawLayer { layer in
			layer.concatenate(attributes.transform.cgAffineTransform)
			applyClip(attributes: attributes, bounds: bounds(for: children), in: &layer)
			let opacity = inheritedOpacity * attributes.opacity
			for child in children {
				render(child, opacity: opacity, in: &layer)
			}
		}
	}

	private func render(viewport data: SVGViewportData, inheritedOpacity: Double, in context: inout GraphicsContext) {
		guard data.attributes.canRender else { return }
		context.drawLayer { layer in
			layer.concatenate(data.attributes.transform.cgAffineTransform)
			applyClip(attributes: data.attributes, bounds: Rect(x: data.x, y: data.y, width: data.width, height: data.height), in: &layer)
			if let viewBox = data.viewBox, let transform = data.preserveAspectRatio.viewBoxTransform(
				from: viewBox,
				to: Rect(x: data.x, y: data.y, width: data.width, height: data.height)
			) {
				layer.concatenate(transform.cgAffineTransform)
			} else {
				layer.concatenate(Transform.identity.translatedBy(x: data.x, y: data.y).cgAffineTransform)
			}
			let opacity = inheritedOpacity * data.attributes.opacity
			for child in data.children {
				render(child, opacity: opacity, in: &layer)
			}
		}
	}

	private func render(use data: SVGUseData, inheritedOpacity: Double, in context: inout GraphicsContext) {
		guard data.attributes.canRender else { return }
		let referenceID = data.href.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
		context.drawLayer { layer in
			layer.concatenate(data.attributes.transform.translatedBy(x: data.x, y: data.y).cgAffineTransform)
			applyClip(attributes: data.attributes, bounds: bounds(for: data), in: &layer)
			let opacity = inheritedOpacity * data.attributes.opacity
			if let elements = document.defs.reusableElements[referenceID] {
				for element in elements {
					render(element, opacity: opacity, in: &layer)
				}
			} else if let symbol = document.defs.symbols[referenceID] {
				render(symbol: symbol, use: data, opacity: opacity, in: &layer)
			}
		}
	}

	private func render(symbol: SVGSymbolData, use data: SVGUseData, opacity: Double, in context: inout GraphicsContext) {
		let width = data.width ?? symbol.width
		let height = data.height ?? symbol.height
		if let viewBox = symbol.viewBox, let transform = symbol.preserveAspectRatio.viewBoxTransform(
			from: viewBox,
			to: Rect(x: symbol.x, y: symbol.y, width: width, height: height)
		) {
			context.concatenate(transform.cgAffineTransform)
		}
		for child in symbol.children {
			render(child, opacity: opacity * symbol.attributes.opacity, in: &context)
		}
	}

	private func render(path cgPath: CGPath, attributes: SVGPaintAttributes, inheritedOpacity: Double, forceStroke: Bool, in context: inout GraphicsContext) {
		guard attributes.canRender else { return }
		context.drawLayer { layer in
			layer.concatenate(attributes.transform.cgAffineTransform)
			let path = SwiftUI.Path(cgPath)
			let pathBounds = cgPath.svgBounds
			applyClip(attributes: attributes, bounds: pathBounds, in: &layer)
			let opacity = inheritedOpacity * attributes.opacity
			for operation in attributes.paintOrder.resolvedOperations {
				switch operation {
				case .fill:
					if !forceStroke {
						fill(path: path, bounds: pathBounds, paint: attributes.fill, currentColor: attributes.color, opacity: opacity * attributes.fillOpacity, fillRule: attributes.fillRule, in: &layer)
					}
				case .stroke:
					if let shading = shading(from: attributes.stroke, currentColor: attributes.color, opacity: opacity * attributes.strokeOpacity, bounds: pathBounds), attributes.strokeWidth > 0 {
						layer.stroke(path, with: shading, style: StrokeStyle(
							lineWidth: CGFloat(attributes.strokeWidth),
							lineCap: attributes.strokeLineCap.cgLineCap,
							lineJoin: attributes.strokeLineJoin.cgLineJoin,
							miterLimit: CGFloat(attributes.strokeMiterLimit),
							dash: attributes.strokeDashArray.map { CGFloat($0) },
							dashPhase: CGFloat(attributes.strokeDashOffset)
						))
					}
				case .markers:
					break
				}
			}
		}
	}

	private func applyClip(attributes: SVGPaintAttributes, bounds: Rect?, in context: inout GraphicsContext) {
		guard let clip = clipPath(from: attributes.clipPath, bounds: bounds) else { return }
		context.clip(to: SwiftUI.Path(clip.path), style: FillStyle(eoFill: clip.fillRule == .evenOdd))
	}

	private func clipPath(from value: SVGClipPathValue, bounds: Rect?) -> SVGRenderClipPath? {
		switch value {
		case .none, .basicShape:
			return nil
		case .url(let id):
			let referenceID = id.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
			guard let definition = document.defs.clipPathDefinitions[referenceID] else { return nil }
			return clipPath(from: definition, bounds: bounds)
		case .geometryBox(let box):
			return clipPath(from: box, bounds: bounds)
		}
	}

	private func clipPath(from definition: SVGClipPathDef, bounds: Rect?) -> SVGRenderClipPath? {
		let rootTransform: Transform
		switch definition.units {
		case .userSpaceOnUse:
			rootTransform = .identity
		case .objectBoundingBox:
			guard let bounds, bounds.width > 0, bounds.height > 0 else { return nil }
			rootTransform = Transform.identity.translatedBy(x: bounds.x, y: bounds.y).scaledBy(x: bounds.width, y: bounds.height)
		}

		let path = CGMutablePath()
		let fillRule = appendClipPathElements(definition.children, transform: rootTransform, to: path)
		guard !path.isEmpty else { return nil }
		return SVGRenderClipPath(path: path, fillRule: fillRule)
	}

	private func clipPath(from box: SVGGeometryBox, bounds: Rect?) -> SVGRenderClipPath? {
		let rect: Rect?
		switch box {
		case .viewBox:
			rect = document.viewBox
		case .contentBox, .paddingBox, .borderBox, .marginBox, .fillBox, .strokeBox:
			rect = bounds
		}
		guard let rect, rect.width > 0, rect.height > 0 else { return nil }
		return SVGRenderClipPath(path: Path(commands: [.rect(rect)]).cgPath, fillRule: .winding)
	}

	@discardableResult
	private func appendClipPathElements(_ elements: [SVGElement], transform: Transform, to path: CGMutablePath) -> FillRule {
		var fillRule = FillRule.winding
		for element in elements {
			let elementFillRule = appendClipPathElement(element, transform: transform, to: path)
			if elementFillRule == .evenOdd {
				fillRule = .evenOdd
			}
		}
		return fillRule
	}

	@discardableResult
	private func appendClipPathElement(_ element: SVGElement, transform: Transform, to path: CGMutablePath) -> FillRule {
		switch element {
		case .path(let data):
			appendClipPath(data.path.cgPath, attributes: data.attributes, transform: transform, to: path)
			return data.attributes.clipRule
		case .rect(let data):
			appendClipPath(data.path.cgPath, attributes: data.attributes, transform: transform, to: path)
			return data.attributes.clipRule
		case .circle(let data):
			appendClipPath(data.path.cgPath, attributes: data.attributes, transform: transform, to: path)
			return data.attributes.clipRule
		case .ellipse(let data):
			appendClipPath(data.path.cgPath, attributes: data.attributes, transform: transform, to: path)
			return data.attributes.clipRule
		case .line(let data):
			appendClipPath(data.path.cgPath, attributes: data.attributes, transform: transform, to: path)
			return data.attributes.clipRule
		case .polygon(let data):
			appendClipPath(data.path.cgPath, attributes: data.attributes, transform: transform, to: path)
			return data.attributes.clipRule
		case .polyline(let data):
			appendClipPath(data.path.cgPath, attributes: data.attributes, transform: transform, to: path)
			return data.attributes.clipRule
		case .group(let data):
			guard data.attributes.canContributeToClip else { return .winding }
			return appendClipPathElements(data.children, transform: transform.concatenating(data.attributes.transform), to: path)
		case .switch(let data):
			guard data.attributes.canContributeToClip else { return .winding }
			return appendClipPathElements(data.children, transform: transform.concatenating(data.attributes.transform), to: path)
		case .link(let data):
			guard data.attributes.canContributeToClip else { return .winding }
			return appendClipPathElements(data.children, transform: transform.concatenating(data.attributes.transform), to: path)
		case .svg(let data):
			guard data.attributes.canContributeToClip else { return .winding }
			var viewportTransform = data.attributes.transform
			if let viewBox = data.viewBox, let transform = data.preserveAspectRatio.viewBoxTransform(
				from: viewBox,
				to: Rect(x: data.x, y: data.y, width: data.width, height: data.height)
			) {
				viewportTransform = viewportTransform.concatenating(transform)
			} else {
				viewportTransform = viewportTransform.translatedBy(x: data.x, y: data.y)
			}
			return appendClipPathElements(data.children, transform: transform.concatenating(viewportTransform), to: path)
		case .unknown(let data):
			guard data.attributes.canContributeToClip else { return .winding }
			return appendClipPathElements(data.children, transform: transform.concatenating(data.attributes.transform), to: path)
		case .foreignObject(let data):
			guard data.attributes.canContributeToClip else { return .winding }
			return appendClipPathElements(data.children, transform: transform.concatenating(data.attributes.transform), to: path)
		case .use(let data):
			return appendUseClipPath(data, transform: transform, to: path)
		case .image, .text:
			return .winding
		}
	}

	private func appendClipPath(_ cgPath: CGPath, attributes: SVGPaintAttributes, transform: Transform, to path: CGMutablePath) {
		guard attributes.canContributeToClip else { return }
		path.addPath(cgPath, transform: transform.concatenating(attributes.transform).cgAffineTransform)
	}

	private func appendUseClipPath(_ data: SVGUseData, transform: Transform, to path: CGMutablePath) -> FillRule {
		guard data.attributes.canContributeToClip else { return .winding }
		let referenceID = data.href.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
		let useTransform = transform.concatenating(data.attributes.transform.translatedBy(x: data.x, y: data.y))
		if let elements = document.defs.reusableElements[referenceID] {
			return appendClipPathElements(elements, transform: useTransform, to: path)
		}
		if let symbol = document.defs.symbols[referenceID] {
			var symbolTransform = Transform.identity
			if let viewBox = symbol.viewBox, let transform = symbol.preserveAspectRatio.viewBoxTransform(
				from: viewBox,
				to: Rect(x: symbol.x, y: symbol.y, width: data.width ?? symbol.width, height: data.height ?? symbol.height)
			) {
				symbolTransform = symbolTransform.concatenating(transform)
			}
			return appendClipPathElements(symbol.children, transform: useTransform.concatenating(symbolTransform), to: path)
		}
		return .winding
	}

	private func fill(path: SwiftUI.Path, bounds: Rect, paint: SVGPaint, currentColor: Color, opacity: Double, fillRule: FillRule, in context: inout GraphicsContext) {
		if let patternID = patternID(from: paint), let pattern = document.defs.patterns[patternID] {
			fill(path: path, bounds: bounds, pattern: pattern, opacity: opacity, fillRule: fillRule, in: &context)
		} else if let shading = shading(from: paint, currentColor: currentColor, opacity: opacity, bounds: bounds) {
			context.fill(path, with: shading, style: FillStyle(eoFill: fillRule == .evenOdd))
		}
	}

	private func fill(path: SwiftUI.Path, bounds: Rect, pattern: SVGPatternDef, opacity: Double, fillRule: FillRule, in context: inout GraphicsContext) {
		guard let tile = tileRect(for: pattern, bounds: bounds), tile.width > 0, tile.height > 0 else { return }
		context.drawLayer { layer in
			layer.clip(to: path, style: FillStyle(eoFill: fillRule == .evenOdd))
			layer.concatenate(pattern.patternTransform.cgAffineTransform)
			let startX = Int(floor((bounds.left - tile.right) / tile.width))
			let endX = Int(ceil((bounds.right - tile.left) / tile.width))
			let startY = Int(floor((bounds.top - tile.bottom) / tile.height))
			let endY = Int(ceil((bounds.bottom - tile.top) / tile.height))
			for column in startX...endX {
				for row in startY...endY {
					layer.drawLayer { tileLayer in
						tileLayer.concatenate(Transform.identity.translatedBy(
							x: tile.x + Double(column) * tile.width,
							y: tile.y + Double(row) * tile.height
						).cgAffineTransform)
						if let viewBox = pattern.viewBox, let transform = pattern.preserveAspectRatio.viewBoxTransform(
							from: viewBox,
							to: Rect(x: 0, y: 0, width: tile.width, height: tile.height)
						) {
							tileLayer.concatenate(transform.cgAffineTransform)
						} else if pattern.patternContentUnits == .objectBoundingBox {
							tileLayer.concatenate(Transform.identity.scaledBy(x: bounds.width, y: bounds.height).cgAffineTransform)
						}
						for child in pattern.children {
							render(child, opacity: opacity * pattern.attributes.opacity, in: &tileLayer)
						}
					}
				}
			}
		}
	}

	private func tileRect(for pattern: SVGPatternDef, bounds: Rect) -> Rect? {
		switch pattern.patternUnits {
		case .userSpaceOnUse:
			Rect(x: pattern.x, y: pattern.y, width: pattern.width, height: pattern.height)
		case .objectBoundingBox:
			Rect(
				x: bounds.x + pattern.x * bounds.width,
				y: bounds.y + pattern.y * bounds.height,
				width: pattern.width * bounds.width,
				height: pattern.height * bounds.height
			)
		}
	}

	private func shading(from paint: SVGPaint, currentColor: Color, opacity: Double, bounds: Rect) -> GraphicsContext.Shading? {
		switch paint {
		case .none, .contextFill, .contextStroke:
			return nil
		case .color(let color):
			return .color(swiftUIColor(from: color, opacity: opacity))
		case .currentColor:
			return .color(swiftUIColor(from: currentColor, opacity: opacity))
		case .url(let id):
			return paintServerShading(id: id, opacity: opacity, bounds: bounds)
		case .urlWithFallback(let id, let fallback):
			return paintServerShading(id: id, opacity: opacity, bounds: bounds) ?? shading(from: fallback, currentColor: currentColor, opacity: opacity, bounds: bounds)
		}
	}

	private func paintServerShading(id: String, opacity: Double, bounds: Rect) -> GraphicsContext.Shading? {
		let referenceID = id.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
		if let gradient = document.defs.linearGradients[referenceID] {
			return linearGradientShading(gradient, opacity: opacity, bounds: bounds)
		}
		if let gradient = document.defs.radialGradients[referenceID] {
			return radialGradientShading(gradient, opacity: opacity, bounds: bounds)
		}
		return nil
	}

	private func linearGradientShading(_ gradient: SVGLinearGradientDef, opacity: Double, bounds: Rect) -> GraphicsContext.Shading? {
		let stops = gradientStops(gradient.stops, opacity: opacity, padEndpoints: gradient.spreadMethod != .pad)
		guard let firstStop = stops.first else { return nil }
		let start = gradientPoint(x: gradient.x1, y: gradient.y1, units: gradient.gradientUnits, bounds: bounds)
			.applying(gradient.gradientTransform)
		let end = gradientPoint(x: gradient.x2, y: gradient.y2, units: gradient.gradientUnits, bounds: bounds)
			.applying(gradient.gradientTransform)
		guard let spread = spreadStops(stops, method: gradient.spreadMethod, lowerBound: linearGradientLowerBound(start: start, end: end, bounds: bounds), upperBound: linearGradientUpperBound(start: start, end: end, bounds: bounds)) else {
			return .color(firstStop.color)
		}
		let vector = end - start
		let spreadStart = start + vector * spread.lowerBound
		let spreadEnd = start + vector * spread.upperBound
		return .linearGradient(
			Gradient(stops: spread.stops),
			startPoint: spreadStart.cgPoint,
			endPoint: spreadEnd.cgPoint
		)
	}

	private func radialGradientShading(_ gradient: SVGRadialGradientDef, opacity: Double, bounds: Rect) -> GraphicsContext.Shading? {
		let stops = gradientStops(gradient.stops, opacity: opacity, padEndpoints: gradient.spreadMethod != .pad)
		guard let firstStop = stops.first else { return nil }
		let center = gradientPoint(x: gradient.cx, y: gradient.cy, units: gradient.gradientUnits, bounds: bounds)
			.applying(gradient.gradientTransform)
		let radius = gradientRadius(gradient.r, units: gradient.gradientUnits, bounds: bounds)
		let startRadius = gradientRadius(gradient.fr, units: gradient.gradientUnits, bounds: bounds)
		let radiusDelta = radius - startRadius
		guard let spread = spreadStops(stops, method: gradient.spreadMethod, lowerBound: 0, upperBound: radialGradientUpperBound(center: center, startRadius: startRadius, radiusDelta: radiusDelta, bounds: bounds)) else {
			return .color(firstStop.color)
		}
		return .radialGradient(
			Gradient(stops: spread.stops),
			center: center.cgPoint,
			startRadius: CGFloat(max(0, startRadius + spread.lowerBound * radiusDelta)),
			endRadius: CGFloat(max(0, startRadius + spread.upperBound * radiusDelta))
		)
	}

	private func gradientStops(_ stops: [SVGGradientStop], opacity: Double, padEndpoints: Bool = false) -> [GradientPaintStop] {
		var paintStops = stops.map { stop in
			GradientPaintStop(color: swiftUIColor(from: stop.color, opacity: opacity * stop.opacity), offset: stop.offset)
		}.sorted { $0.offset < $1.offset }
		if padEndpoints, let first = paintStops.first, first.offset > 0 {
			paintStops.insert(GradientPaintStop(color: first.color, offset: 0), at: 0)
		}
		if padEndpoints, let last = paintStops.last, last.offset < 1 {
			paintStops.append(GradientPaintStop(color: last.color, offset: 1))
		}
		return paintStops
	}

	private func spreadStops(_ stops: [GradientPaintStop], method: SVGGradientSpreadMethod, lowerBound: Double?, upperBound: Double?) -> SpreadGradientStops? {
		guard let lowerBound, let upperBound, lowerBound.isFinite, upperBound.isFinite, upperBound > lowerBound else { return nil }
		switch method {
		case .pad:
			return SpreadGradientStops(lowerBound: 0, upperBound: 1, stops: stops.map(\.gradientStop))
		case .repeat, .reflect:
			let firstCycle = floor(lowerBound)
			let lastCycle = ceil(upperBound)
			let cycleCount = Int(lastCycle - firstCycle)
			guard cycleCount > 0, cycleCount <= 512 else { return nil }
			let denominator = lastCycle - firstCycle
			let spreadStops = (0..<cycleCount).flatMap { cycleIndex in
				let cycle = firstCycle + Double(cycleIndex)
				let reflectedCycle = method == .reflect && Int(cycle) % 2 != 0
				let cycleStops = reflectedCycle ? Array(stops.reversed()) : stops
				return cycleStops.map { stop in
					let offset = reflectedCycle ? 1 - stop.offset : stop.offset
					return Gradient.Stop(color: stop.color, location: (cycle + offset - firstCycle) / denominator)
				}
			}.sorted { $0.location < $1.location }
			return SpreadGradientStops(lowerBound: firstCycle, upperBound: lastCycle, stops: spreadStops)
		}
	}

	private func gradientPoint(x: Double, y: Double, units: SVGGradientUnits, bounds: Rect) -> Point {
		switch units {
		case .userSpaceOnUse:
			Point(x, y)
		case .objectBoundingBox:
			Point(bounds.x + x * bounds.width, bounds.y + y * bounds.height)
		}
	}

	private func gradientRadius(_ radius: Double, units: SVGGradientUnits, bounds: Rect) -> Double {
		switch units {
		case .userSpaceOnUse:
			radius
		case .objectBoundingBox:
			radius * max(bounds.width, bounds.height)
		}
	}

	private func linearGradientLowerBound(start: Point, end: Point, bounds: Rect) -> Double? {
		linearGradientProjections(start: start, end: end, bounds: bounds)?.min()
	}

	private func linearGradientUpperBound(start: Point, end: Point, bounds: Rect) -> Double? {
		linearGradientProjections(start: start, end: end, bounds: bounds)?.max()
	}

	private func linearGradientProjections(start: Point, end: Point, bounds: Rect) -> [Double]? {
		let vector = end - start
		let lengthSquared = vector.x * vector.x + vector.y * vector.y
		guard lengthSquared > 0 else { return nil }
		return [bounds.topLeft, bounds.topRight, bounds.bottomRight, bounds.bottomLeft].map { point in
			let relative = point - start
			return (relative.x * vector.x + relative.y * vector.y) / lengthSquared
		}
	}

	private func radialGradientUpperBound(center: Point, startRadius: Double, radiusDelta: Double, bounds: Rect) -> Double? {
		guard radiusDelta > 0 else { return nil }
		return [bounds.topLeft, bounds.topRight, bounds.bottomRight, bounds.bottomLeft]
			.map { (max(0, $0.distance(to: center) - startRadius)) / radiusDelta }
			.max()
	}

	private func patternID(from paint: SVGPaint) -> String? {
		switch paint {
		case .url(let id), .urlWithFallback(let id, _):
			let referenceID = id.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
			return document.defs.patterns[referenceID] == nil ? nil : referenceID
		case .none, .color, .currentColor, .contextFill, .contextStroke:
			return nil
		}
	}

	private func swiftUIColor(from paint: SVGPaint, currentColor: Color, opacity: Double) -> SwiftUI.Color? {
		switch paint {
		case .none, .url, .contextFill, .contextStroke:
			return nil
		case .color(let color):
			return SwiftUI.Color(red: color.red, green: color.green, blue: color.blue, opacity: color.alpha * opacity)
		case .currentColor:
			return SwiftUI.Color(red: currentColor.red, green: currentColor.green, blue: currentColor.blue, opacity: currentColor.alpha * opacity)
		case .urlWithFallback(_, let fallback):
			return swiftUIColor(from: fallback, currentColor: currentColor, opacity: opacity)
		}
	}

	private func swiftUIColor(from color: Color, opacity: Double) -> SwiftUI.Color {
		SwiftUI.Color(red: color.red, green: color.green, blue: color.blue, opacity: color.alpha * opacity)
	}

	private func bounds(for elements: [SVGElement]) -> Rect? {
		bounds(for: elements, transform: .identity)
	}

	private func bounds(for elements: [SVGElement], transform: Transform) -> Rect? {
		elements.reduce(nil) { partial, element in
			partial.union(bounds(for: element, transform: transform))
		}
	}

	private func bounds(for element: SVGElement, transform: Transform) -> Rect? {
		switch element {
		case .path(let data):
			return bounds(for: data.path.cgPath, transform: transform.concatenating(data.attributes.transform))
		case .rect(let data):
			return bounds(for: data.path.cgPath, transform: transform.concatenating(data.attributes.transform))
		case .circle(let data):
			return bounds(for: data.path.cgPath, transform: transform.concatenating(data.attributes.transform))
		case .ellipse(let data):
			return bounds(for: data.path.cgPath, transform: transform.concatenating(data.attributes.transform))
		case .line(let data):
			return bounds(for: data.path.cgPath, transform: transform.concatenating(data.attributes.transform))
		case .polygon(let data):
			return bounds(for: data.path.cgPath, transform: transform.concatenating(data.attributes.transform))
		case .polyline(let data):
			return bounds(for: data.path.cgPath, transform: transform.concatenating(data.attributes.transform))
		case .group(let data):
			return bounds(for: data.children, transform: transform.concatenating(data.attributes.transform))
		case .switch(let data):
			return bounds(for: data.children, transform: transform.concatenating(data.attributes.transform))
		case .link(let data):
			return bounds(for: data.children, transform: transform.concatenating(data.attributes.transform))
		case .svg(let data):
			let viewport = Rect(x: data.x, y: data.y, width: data.width, height: data.height)
			return bounds(for: Path(commands: [.rect(viewport)]).cgPath, transform: transform.concatenating(data.attributes.transform))
		case .unknown(let data):
			return bounds(for: data.children, transform: transform.concatenating(data.attributes.transform))
		case .foreignObject(let data):
			return bounds(for: data.children, transform: transform.concatenating(data.attributes.transform))
		case .use(let data):
			return bounds(for: data, transform: transform)
		case .image(let data):
			let imageBounds = Path(commands: [.rect(Rect(x: data.x, y: data.y, width: data.width, height: data.height))]).cgPath
			return bounds(for: imageBounds, transform: transform.concatenating(data.attributes.transform))
		case .text:
			return nil
		}
	}

	private func bounds(for data: SVGUseData, transform: Transform = .identity) -> Rect? {
		let referenceID = data.href.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
		let useTransform = transform.concatenating(data.attributes.transform.translatedBy(x: data.x, y: data.y))
		if let elements = document.defs.reusableElements[referenceID] {
			return bounds(for: elements, transform: useTransform)
		}
		if let symbol = document.defs.symbols[referenceID] {
			let width = data.width ?? symbol.width
			let height = data.height ?? symbol.height
			if let viewBox = symbol.viewBox, let symbolTransform = symbol.preserveAspectRatio.viewBoxTransform(
				from: viewBox,
				to: Rect(x: symbol.x, y: symbol.y, width: width, height: height)
			) {
				return bounds(for: symbol.children, transform: useTransform.concatenating(symbolTransform))
			}
			return bounds(for: symbol.children, transform: useTransform)
		}
		return nil
	}

	private func bounds(for cgPath: CGPath, transform: Transform) -> Rect? {
		let bounds = cgPath.boundingBoxOfPath.applying(transform.cgAffineTransform)
		guard bounds.width > 0, bounds.height > 0 else { return nil }
		return Rect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: bounds.height)
	}
}

/// A native SwiftUI gradient stop prepared from an SVG `<stop>` element.
private struct GradientPaintStop {
	var color: SwiftUI.Color
	var offset: Double

	var gradientStop: Gradient.Stop {
		Gradient.Stop(color: color, location: offset)
	}
}

/// A synthesized stop list and coordinate span for a spread gradient.
private struct SpreadGradientStops {
	var lowerBound: Double
	var upperBound: Double
	var stops: [Gradient.Stop]
}

/// A prepared native clipping path and the winding rule SwiftUI should use for it.
private struct SVGRenderClipPath {
	var path: CGPath
	var fillRule: FillRule
}

private extension Rect {
	var aspectRatio: CGFloat? {
		guard width > 0, height > 0 else { return nil }
		return CGFloat(width / height)
	}

	func union(_ other: Rect?) -> Rect {
		guard let other else { return self }
		let minX = min(left, other.left)
		let minY = min(top, other.top)
		let maxX = max(right, other.right)
		let maxY = max(bottom, other.bottom)
		return Rect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
	}
}

private extension Optional where Wrapped == Rect {
	func union(_ other: Rect?) -> Rect? {
		switch (self, other) {
		case (.some(let lhs), .some(let rhs)):
			return lhs.union(rhs)
		case (.some(let lhs), .none):
			return lhs
		case (.none, .some(let rhs)):
			return rhs
		case (.none, .none):
			return nil
		}
	}
}

private extension SVGPaintAttributes {
	var canRender: Bool {
		display != .none && visibility == .visible && opacity > 0
	}

	var canContributeToClip: Bool {
		display != .none
	}
}

private extension CGPath {
	var svgBounds: Rect {
		let bounds = boundingBoxOfPath
		return Rect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: bounds.height)
	}
}
