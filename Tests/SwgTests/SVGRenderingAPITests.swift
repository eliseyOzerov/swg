import CoreGraphics
import Foundation
import SwiftUI
import Testing
@testable import Swg

@Test func svgPathConvertsToCoreGraphicsPath() {
	let path = SVGRectData(id: "box", x: 2, y: 3, width: 10, height: 12, rx: 0, ry: 0, attributes: .defaults).path
	let cgPath = path.cgPath

	#expect(cgPath.boundingBox == CGRect(x: 2, y: 3, width: 10, height: 12))
}

@Test func svgGeometryConvertsToCoreGraphicsTypes() {
	let point = Point(3, 4)
	let rect = Rect(x: 1, y: 2, width: 5, height: 8)
	let transform = Transform.identity.translatedBy(x: 7, y: 9)

	#expect(point.cgPoint == CGPoint(x: 3, y: 4))
	#expect(rect.cgRect == CGRect(x: 1, y: 2, width: 5, height: 8))
	#expect(CGPoint(x: 1, y: 1).applying(transform.cgAffineTransform) == CGPoint(x: 8, y: 10))
}

@MainActor @Test func svgCanBeCreatedFromDocumentOrSource() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
		<circle id="dot" cx="12" cy="12" r="4" fill="red"/>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let documentView = SVG(document, options: SVGRenderOptions(opacity: 0.8))
	let sourceView = try #require(SVG(source: svg))

	#expect(documentView.document?.viewBox == Rect(x: 0, y: 0, width: 24, height: 24))
	#expect(documentView.options.opacity == 0.8)
	#expect(sourceView.document?.elementIDs == ["dot"])
}

@MainActor @Test func svgCanRenderFromDocumentBindings() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
		<circle id="dot" cx="12" cy="12" r="4" fill="red"/>
	</svg>
	"""
	let document = try #require(SVGParser().parse(svg))

	let optionalView = SVG(Binding<SVGDocument?>.constant(document))
	let requiredView = SVG(Binding<SVGDocument>.constant(document))

	#expect(optionalView.document?.elementIDs == ["dot"])
	#expect(requiredView.document?.elementIDs == ["dot"])
}

@MainActor @Test func svgCanBeCreatedFromURLAssetAndFileSources() throws {
	let remoteURL = try #require(URL(string: "https://example.com/icon.svg"))
	let simpleAssetView = SVG("basic-paint", bundle: .module)
	let simpleAssetPathView = SVG("VisualFixtures/basic-paint.svg", bundle: .module)
	let assetView = SVG(asset: "basic-paint", bundle: .module, fileExtension: "svg", subdirectory: "VisualFixtures")
	let fileURL = try #require(
		Bundle.module.url(forResource: "basic-paint", withExtension: "svg", subdirectory: "VisualFixtures")
			?? Bundle.module.url(forResource: "basic-paint", withExtension: "svg")
	)

	let urlView = SVG(url: remoteURL)
	let fileURLView = SVG(file: fileURL)
	let filePathView = SVG(file: fileURL.path)

	#expect(urlView.document == nil)
	#expect(simpleAssetView.document == nil)
	#expect(simpleAssetPathView.document == nil)
	#expect(assetView.document == nil)
	#expect(fileURLView.document == nil)
	#expect(filePathView.document == nil)
}

@Test func svgBundleResourceResolvesSimpleNamesAndRelativePaths() throws {
	let simpleURL = try #require(SVGBundleResource.url(for: "basic-paint", in: .module))
	let pathURL = try #require(SVGBundleResource.url(for: "VisualFixtures/basic-paint.svg", in: .module))

	#expect(simpleURL.lastPathComponent == "basic-paint.svg")
	#expect(pathURL.lastPathComponent == "basic-paint.svg")
}

@Test func svgDocumentLoaderParsesFileSource() async throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
		<circle id="dot" cx="12" cy="12" r="4" fill="red"/>
	</svg>
	"""
	let fileURL = FileManager.default.temporaryDirectory
		.appendingPathComponent(UUID().uuidString)
		.appendingPathExtension("svg")
	try svg.write(to: fileURL, atomically: true, encoding: .utf8)
	defer { try? FileManager.default.removeItem(at: fileURL) }

	let document = try #require(await SVGDocumentLoader.load(from: .file(fileURL)))

	#expect(document.elementIDs == ["dot"])
}
