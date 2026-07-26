import Testing
@testable import Swg

@Test func svgDocumentFindsNestedElementByID() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
		<g id="icon">
			<circle id="dot" cx="12" cy="12" r="4" fill="blue"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let element = try #require(document.element(id: "dot"))

	#expect(element.elementID == "dot")
	guard case .circle(let circle) = element else {
		Issue.record("Expected nested element lookup to return the circle")
		return
	}
	#expect(circle.attributes.fill == .color(.blue))
}

@Test func svgDocumentModifiesElementAttributesByID() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
		<g id="icon">
			<path id="mark" d="M4 12 L10 18 L20 6" fill="none" stroke="blue"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let highlighted = document.modifyingElement(id: "mark") { element in
		element.modifyingAttributes { attributes in
			attributes.stroke = .color(.red)
			attributes.strokeWidth = 3
			attributes.transform = attributes.transform.translatedBy(x: 2, y: 1)
		}
	}

	let element = try #require(highlighted.element(id: "mark"))
	guard case .path(let path) = element else {
		Issue.record("Expected modified element to remain a path")
		return
	}
	#expect(path.attributes.stroke == .color(.red))
	#expect(path.attributes.strokeWidth == 3)
	#expect(path.attributes.transform == Transform.identity.translatedBy(x: 2, y: 1))
}

@Test func svgDocumentMapsElementsRecursively() throws {
	let svg = """
	<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
		<g id="layer">
			<rect id="card" width="24" height="24" fill="blue"/>
			<circle id="dot" cx="12" cy="12" r="4" fill="red"/>
		</g>
	</svg>
	"""

	let document = try #require(SVGParser().parse(svg))
	let hidden = document.mapElements { element in
		element.modifyingAttributes { attributes in
			attributes.display = .none
		}
	}

	for id in ["layer", "card", "dot"] {
		let element = try #require(hidden.element(id: id))
		#expect(element.attributes?.display == SVGDisplay.none)
	}
}
