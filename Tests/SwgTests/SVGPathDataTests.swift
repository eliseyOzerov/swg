import Testing
@testable import Swg

@Test func svgPathParserHandlesRelativeLinesAndClose() {
	let path = SVGPathDataParser.parse("M 10 10 h 20 v 15 l -5 5 z")

	#expect(path.commands == [
		.move(to: Point(10, 10)),
		.line(to: Point(30, 10)),
		.line(to: Point(30, 25)),
		.line(to: Point(25, 30)),
		.close,
	])
}

@Test func svgPathParserHandlesSmoothCubicReflection() {
	let path = SVGPathDataParser.parse("M 0 0 C 10 0 20 10 30 10 S 50 20 60 0")

	#expect(path.commands.count == 3)
	guard case .cubic(let end, let control1, let control2) = path.commands[2] else {
		Issue.record("Expected second curve to be cubic")
		return
	}

	#expect(control1 == Point(40, 10))
	#expect(control2 == Point(50, 20))
	#expect(end == Point(60, 0))
}

@Test func svgPathParserHandlesQuadraticBezierCommands() {
	let path = SVGPathDataParser.parse("M 10 10 Q 15 5 20 10 q 5 5 10 0")

	#expect(path.commands == [
		.move(to: Point(10, 10)),
		.quad(to: Point(20, 10), control: Point(15, 5)),
		.quad(to: Point(30, 10), control: Point(25, 15)),
	])
}

@Test func svgPathParserConvertsArcsToCubics() throws {
	let path = SVGPathDataParser.parse("M 0 0 A 10 10 0 0 1 10 10")

	#expect(path.commands.count == 2)
	guard case .cubic(let end, _, _) = path.commands[1] else {
		Issue.record("Expected arc to become a cubic")
		return
	}

	#expect(end.distance(to: Point(10, 10)) < 0.000001)
}

@Test func svgPathDataSerializesEditableCommands() {
	let path = Path(commands: [
		.move(to: Point(0, 0)),
		.line(to: Point(10, 0)),
		.quad(to: Point(20, 0), control: Point(15, 5)),
		.cubic(to: Point(30, 0), control1: Point(22.5, 6.25), control2: Point(28, 2)),
		.close,
	])

	let data = path.svgPathData(precision: 2)

	#expect(data == "M 0 0 L 10 0 Q 15 5 20 0 C 22.5 6.25 28 2 30 0 Z")
	#expect(Path(svgPathData: data).commands == path.commands)
}

@Test func svgPathDataCanCreatePathElementFromPath() {
	let path = Path(commands: [
		.move(to: Point(1, 2)),
		.line(to: Point(3, 4)),
	])

	let element = SVGPathData(id: "stroke", path: path)

	#expect(element.id == "stroke")
	#expect(element.d == "M 1 2 L 3 4")
	#expect(element.path.commands == path.commands)
}
