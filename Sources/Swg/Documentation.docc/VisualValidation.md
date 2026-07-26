# Visual Validation

Use fixture-backed raster comparisons for SVG features that affect rendered output.

## Overview

`swg` has two validation layers:

- Focused parser and model tests prove that an SVG feature is recognized, normalized, inherited, preserved, or converted into the expected Swift value.
- Visual tests prove that render-affecting features produce the expected pixel-level output for a bounded fixture.

The SVG coverage checklist is test-gated. A feature can be checked when it has focused tests. Visual fixtures are an additional requirement for features whose behavior should be visible in the eventual `CGPath` and SwiftUI rendering pipeline.

## Feature Gallery

The README feature gallery uses larger documentation SVGs from `docs/feature-gallery/svg`. They are rendered by `docs/FeatureGallery.playground/Contents.swift`, which parses each SVG with ``SVGParser`` and writes PNG previews to `docs/feature-gallery/png`.

Those gallery examples are intended for human-facing documentation. The smaller fixtures below are intended for stable regression checks.

## Fixture Layout

Visual fixtures live in `Tests/SwgTests/VisualFixtures`. Each case has one `.svg` input and one `.golden.txt` output file with the same base name:

```text
Tests/SwgTests/VisualFixtures/basic-paint.svg
Tests/SwgTests/VisualFixtures/basic-paint.golden.txt
```

Add a test in `SVGVisualValidationTests.swift` that calls the shared fixture assertion:

```swift
@Test func svgVisualValidationRendersBasicPaintFixture() throws {
	try assertVisualFixture("basic-paint")
}
```

## Golden Format

Golden files are top-to-bottom rows in SVG/user-space order. Each character represents one pixel in the deterministic raster:

```text
. transparent
W white
R red
G green
B blue
? opaque color outside the named buckets
```

The current rasterizer disables antialiasing and compares symbolic color buckets instead of storing binary snapshots. That keeps fixtures small, readable, and easy to review.

## Current Scope

The first visual fixtures cover basic paint and transforms. The test rasterizer currently supports the shape and container subset needed for those fixtures: paths, rectangles, circles, ellipses, lines, polygons, polylines, groups, links, switches, nested SVG content, foreign objects, and unknown containers.

Future visual fixtures should be added as rendering support expands through paint order, fill rules, strokes, clipping, masking, gradients, filters, text, image handling, reuse, and viewport behavior.
