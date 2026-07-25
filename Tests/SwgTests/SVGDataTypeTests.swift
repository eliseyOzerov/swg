import Testing
@testable import Swg

@Test func svgIntegerParserParsesSignedDigitSequences() {
	#expect(SVGIntegerParser.parse("0") == 0)
	#expect(SVGIntegerParser.parse("42") == 42)
	#expect(SVGIntegerParser.parse("+42") == 42)
	#expect(SVGIntegerParser.parse("-42") == -42)
	#expect(SVGIntegerParser.parse(" 2147483647 ") == 2147483647)
	#expect(SVGIntegerParser.parse("-2147483648") == -2147483648)
}

@Test func svgIntegerParserRejectsNonIntegerSyntax() {
	#expect(SVGIntegerParser.parse("") == nil)
	#expect(SVGIntegerParser.parse("+") == nil)
	#expect(SVGIntegerParser.parse("1.0") == nil)
	#expect(SVGIntegerParser.parse("1e2") == nil)
	#expect(SVGIntegerParser.parse("10px") == nil)
	#expect(SVGIntegerParser.parse("1 2") == nil)
}

@Test func svgLengthParserParsesUnitlessLengthsAsUserUnits() {
	#expect(SVGLengthParser.parseUnitless("0") == 0)
	#expect(SVGLengthParser.parseUnitless("42") == 42)
	#expect(SVGLengthParser.parseUnitless(" +.5 ") == 0.5)
	#expect(SVGLengthParser.parseUnitless("-.25e2") == -25)
}

@Test func svgLengthParserRejectsUnitsForUnitlessLengthParsing() {
	#expect(SVGLengthParser.parseUnitless("") == nil)
	#expect(SVGLengthParser.parseUnitless("10px") == nil)
	#expect(SVGLengthParser.parseUnitless("10pt") == nil)
	#expect(SVGLengthParser.parseUnitless("10%") == nil)
	#expect(SVGLengthParser.parseUnitless("1 2") == nil)
}
