/// CPU-side triangle clipping primitives for the Atlas Anatomy cross-section engine.
///
/// Coordinates are model-local. The retained half-space is
/// dot(position - planePoint, planeNormal) >= 0.
/// This module deliberately returns open cut contours separately: renderers
/// must triangulate those contours into cap faces before calling a section
/// watertight. It does not silently pretend an open surface is a solid cut.
import 'dart:math' as math;

class SectionVector3 {
  final double x, y, z;
  const SectionVector3(this.x, this.y, this.z);

  SectionVector3 operator +(SectionVector3 other) =>
      SectionVector3(x + other.x, y + other.y, z + other.z);
  SectionVector3 operator -(SectionVector3 other) =>
      SectionVector3(x - other.x, y - other.y, z - other.z);
  SectionVector3 operator *(double scale) =>
      SectionVector3(x * scale, y * scale, z * scale);
  double dot(SectionVector3 other) => x * other.x + y * other.y + z * other.z;
  double get length => math.sqrt(dot(this));
  SectionVector3 normalized() {
    final magnitude = length;
    if (magnitude < 1e-12) {
      throw ArgumentError('Section plane normal must not be zero.');
    }
    return this * (1 / magnitude);
  }
}

/// A triangle soup: every consecutive three vertices form one triangle.
class SectionTriangleMesh {
  final List<SectionVector3> vertices;
  const SectionTriangleMesh(this.vertices)
      : assert(vertices.length % 3 == 0);
}

/// A clipped triangle soup and line segments forming the exposed cut boundary.
class SectionClipResult {
  final SectionTriangleMesh surface;
  final List<List<SectionVector3>> cutSegments;
  final int sourceTriangleCount;
  final int clippedTriangleCount;

  const SectionClipResult({
    required this.surface,
    required this.cutSegments,
    required this.sourceTriangleCount,
    required this.clippedTriangleCount,
  });

  bool get hasCut => cutSegments.isNotEmpty;
}

/// Clips triangles against a plane using Sutherland-Hodgman polygon clipping.
///
/// Intersections are linearly interpolated in model-local space. Each clipped
/// polygon is fan-triangulated; degenerate triangles are discarded. The
/// intersection segments are preserved for contour stitching/cap generation.
class AnatomyCrossSectionGeometry {
  static const double _epsilon = 1e-8;

  SectionClipResult clip({
    required SectionTriangleMesh mesh,
    required SectionVector3 planePoint,
    required SectionVector3 planeNormal,
    bool keepPositiveSide = true,
  }) {
    if (mesh.vertices.length % 3 != 0) {
      throw ArgumentError('Triangle mesh vertex count must be divisible by 3.');
    }
    final normal = planeNormal.normalized();
    final output = <SectionVector3>[];
    final segments = <List<SectionVector3>>[];
    var clippedCount = 0;
    final triangleCount = mesh.vertices.length ~/ 3;

    double distance(SectionVector3 p) {
      final d = (p - planePoint).dot(normal);
      return keepPositiveSide ? d : -d;
    }

    SectionVector3 intersection(
        SectionVector3 a, SectionVector3 b, double da, double db) {
      final denominator = da - db;
      if (denominator.abs() < _epsilon) return a;
      final t = (da / denominator).clamp(0.0, 1.0);
      return a + (b - a) * t;
    }

    for (var i = 0; i < mesh.vertices.length; i += 3) {
      final triangle = <SectionVector3>[
        mesh.vertices[i],
        mesh.vertices[i + 1],
        mesh.vertices[i + 2],
      ];
      final distances = triangle.map(distance).toList();
      final polygon = <SectionVector3>[];
      final crossings = <SectionVector3>[];

      for (var edge = 0; edge < 3; edge++) {
        final next = (edge + 1) % 3;
        final a = triangle[edge], b = triangle[next];
        final da = distances[edge], db = distances[next];
        final aInside = da >= -_epsilon;
        final bInside = db >= -_epsilon;

        if (aInside && bInside) {
          polygon.add(b);
        } else if (aInside && !bInside) {
          final p = intersection(a, b, da, db);
          polygon.add(p);
          crossings.add(p);
        } else if (!aInside && bInside) {
          final p = intersection(a, b, da, db);
          polygon.add(p);
          polygon.add(b);
          crossings.add(p);
        }
      }

      if (polygon.length >= 3) {
        for (var j = 1; j < polygon.length - 1; j++) {
          final a = polygon[0], b = polygon[j], c = polygon[j + 1];
          final areaVector = (b - a);
          final crossX = areaVector.y * (c - a).z - areaVector.z * (c - a).y;
          final crossY = areaVector.z * (c - a).x - areaVector.x * (c - a).z;
          final crossZ = areaVector.x * (c - a).y - areaVector.y * (c - a).x;
          if (crossX * crossX + crossY * crossY + crossZ * crossZ >
              _epsilon * _epsilon) {
            output.addAll([a, b, c]);
          }
        }
      }
      if (crossings.length == 2 &&
          (crossings[0] - crossings[1]).length > _epsilon) {
        segments.add(List.unmodifiable(crossings));
      }
      if (polygon.length != 3) clippedCount++;
    }

    return SectionClipResult(
      surface: SectionTriangleMesh(List.unmodifiable(output)),
      cutSegments: List.unmodifiable(segments),
      sourceTriangleCount: triangleCount,
      clippedTriangleCount: clippedCount,
    );
  }
}
