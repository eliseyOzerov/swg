import CoreGraphics
import Foundation
import ImageIO
import Swg
import SwiftUI
import UniformTypeIdentifiers

struct FeatureExample {
	let slug: String
	let width: Int
	let height: Int
}

let featureExamples = [
	FeatureExample(slug: "shapes-basic", width: 720, height: 480),
	FeatureExample(slug: "shapes-rounded-polygons", width: 720, height: 480),
	FeatureExample(slug: "path-lines-curves", width: 720, height: 480),
	FeatureExample(slug: "path-arcs-fillrule", width: 720, height: 480),
	FeatureExample(slug: "viewports-containers", width: 720, height: 480),
	FeatureExample(slug: "transforms-style", width: 720, height: 480),
	FeatureExample(slug: "paint-fill-opacity", width: 720, height: 480),
	FeatureExample(slug: "paint-strokes", width: 720, height: 480),
	FeatureExample(slug: "gradients-patterns", width: 720, height: 480),
	FeatureExample(slug: "clip-mask-composite", width: 720, height: 480),
	FeatureExample(slug: "filters", width: 720, height: 480),
	FeatureExample(slug: "text", width: 720, height: 480),
	FeatureExample(slug: "reuse-markers", width: 720, height: 480),
	FeatureExample(slug: "embedded-animation", width: 720, height: 480),
]

let arguments = CommandLine.arguments.dropFirst()
let explicitPackageRoot = arguments.first.map { URL(fileURLWithPath: $0) }
let explicitPNGDirectory = arguments.dropFirst().first.map { URL(fileURLWithPath: $0, isDirectory: true) }
let inferredPackageRoot = URL(fileURLWithPath: #filePath)
	.deletingLastPathComponent()
	.deletingLastPathComponent()
	.deletingLastPathComponent()
let packageRoot = explicitPackageRoot ?? inferredPackageRoot

try await FeatureGalleryRenderer.renderAll(examples: featureExamples, packageRoot: packageRoot, pngDirectory: explicitPNGDirectory)

enum FeatureGalleryRenderer {
	@MainActor
	static func renderAll(examples: [FeatureExample], packageRoot: URL, pngDirectory explicitPNGDirectory: URL? = nil) throws {
		let svgDirectory = packageRoot.appendingPathComponent("docs/feature-gallery/svg", isDirectory: true)
		let pngDirectory = explicitPNGDirectory ?? packageRoot.appendingPathComponent("docs/feature-gallery/png", isDirectory: true)
		try FileManager.default.createDirectory(at: pngDirectory, withIntermediateDirectories: true)

		for example in examples {
			let svgURL = svgDirectory.appendingPathComponent("\(example.slug).svg")
			let pngURL = pngDirectory.appendingPathComponent("\(example.slug).png")
			let document = try parseDocument(svgURL)
			try render(document, pngURL: pngURL, width: example.width, height: example.height)
			print("Rendered \(pngURL.path)")
		}
	}

	private static func parseDocument(_ svgURL: URL) throws -> SVGDocument {
		let svg = try String(contentsOf: svgURL, encoding: .utf8)
		guard let document = SVGParser().parse(svg) else {
			throw FeatureGalleryError.invalidSVG(svgURL.lastPathComponent)
		}
		return document
	}

	@MainActor
	private static func render(_ document: SVGDocument, pngURL: URL, width: Int, height: Int) throws {
		let renderer = ImageRenderer(content: SVG(document).frame(width: CGFloat(width), height: CGFloat(height)))
		renderer.scale = 1
		guard let image = renderer.cgImage else {
			throw FeatureGalleryError.renderingFailed(pngURL.lastPathComponent)
		}
		if FileManager.default.fileExists(atPath: pngURL.path) {
			try FileManager.default.removeItem(at: pngURL)
		}
		guard let destination = CGImageDestinationCreateWithURL(pngURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
			throw FeatureGalleryError.invalidRenderedPNG(pngURL)
		}
		CGImageDestinationAddImage(destination, image, nil)
		guard CGImageDestinationFinalize(destination) else {
			throw FeatureGalleryError.invalidRenderedPNG(pngURL)
		}
	}
}

enum FeatureGalleryError: Error {
	case invalidSVG(String)
	case renderingFailed(String)
	case invalidRenderedPNG(URL)
}
