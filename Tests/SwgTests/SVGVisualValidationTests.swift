#if canImport(UIKit)
import CoreGraphics
import Foundation
import SwiftUI
import Testing
import UIKit
@testable import Swg

@MainActor @Test func svgVisualValidationRendersBasicPaintFixture() throws {
	try assertVisualFixture("basic-paint")
}

@MainActor @Test func svgVisualValidationRendersTransformFixture() throws {
	try assertVisualFixture("transforms")
}

@MainActor @Test func svgVisualValidationRendersPaintServerFixture() throws {
	try assertVisualFixture("paint-servers")
}

@MainActor @Test func svgVisualValidationRendersClippingFixture() throws {
	try assertVisualFixture("clipping")
}

@MainActor @Test func svgVisualValidationRendersMaskingFixture() throws {
	try assertVisualFixture("masking")
}

@MainActor private func assertVisualFixture(_ name: String) throws {
	let svgURL = try #require(visualFixtureURL(for: name, extension: "svg"))
	let goldenURL = try #require(visualFixtureURL(for: name, extension: "golden.txt"))
	let svg = try String(contentsOf: svgURL, encoding: .utf8)
	let golden = try String(contentsOf: goldenURL, encoding: .utf8)
		.split(whereSeparator: \.isNewline)
		.map(String.init)

	let document = try #require(SVGParser().parse(svg))
	let raster = try SVGVisualRasterizer.render(document, width: golden.first?.count ?? 0, height: golden.count)
	#expect(raster.symbolRows == golden)
}

private func visualFixtureURL(for name: String, extension fileExtension: String) -> URL? {
	Bundle.module.url(forResource: name, withExtension: fileExtension, subdirectory: "VisualFixtures")
		?? Bundle.module.url(forResource: name, withExtension: fileExtension)
}

private struct SVGVisualRasterizer {
	@MainActor
	static func render(_ document: SVGDocument, width: Int, height: Int) throws -> SVGVisualRaster {
		#expect(width > 0)
		#expect(height > 0)
		let renderer = ImageRenderer(content: SVG(document).frame(width: CGFloat(width), height: CGFloat(height)))
		renderer.scale = 1
		let uiImage = try #require(renderer.uiImage)
		let image = try #require(uiImage.cgImage)
		return try SVGVisualRaster(cgImage: image)
	}
}

private struct SVGVisualRaster {
	let width: Int
	let height: Int
	let pixels: [UInt8]

	init(cgImage: CGImage) throws {
		let width = cgImage.width
		let height = cgImage.height
		var pixels = [UInt8](repeating: 0, count: width * height * 4)
		try pixels.withUnsafeMutableBytes { rawPixels in
			let colorSpace = CGColorSpaceCreateDeviceRGB()
			let context = try #require(CGContext(
				data: rawPixels.baseAddress,
				width: width,
				height: height,
				bitsPerComponent: 8,
				bytesPerRow: width * 4,
				space: colorSpace,
				bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
			))
			context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
		}
		self.width = width
		self.height = height
		self.pixels = pixels
	}

	var symbolRows: [String] {
		(0..<height).map { y in
			String((0..<width).map { symbol(atX: $0, y: y) })
		}
	}

	private func symbol(atX x: Int, y: Int) -> Character {
		let index = (y * width + x) * 4
		let red = pixels[index]
		let green = pixels[index + 1]
		let blue = pixels[index + 2]
		let alpha = pixels[index + 3]
		if alpha < 16 { return "." }
		if red > 240, green > 240, blue > 240 { return "W" }
		if red > 200, green < 80, blue < 80 { return "R" }
		if red < 80, green > 200, blue < 80 { return "G" }
		if red < 80, green < 80, blue > 200 { return "B" }
		if red > 80, green < 120, blue > 80 { return "P" }
		return "?"
	}
}

#endif
