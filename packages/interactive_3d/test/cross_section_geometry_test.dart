import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_3d/src/cross_section_geometry.dart';

void main() {
  group('AnatomyCrossSectionGeometry', () {
    final clipper = AnatomyCrossSectionGeometry();

    test('keeps a fully retained triangle unchanged', () {
      const mesh = SectionTriangleMesh([
        SectionVector3(0, 0, 1),
        SectionVector3(1, 0, 1),
        SectionVector3(0, 1, 1),
      ]);
      final result = clipper.clip(
        mesh: mesh,
        planePoint: const SectionVector3(0, 0, 0),
        planeNormal: const SectionVector3(0, 0, 1),
      );
      expect(result.surface.vertices.length, 3);
      expect(result.cutSegments, isEmpty);
    });

    test('clips a triangle and returns its cut edge', () {
      const mesh = SectionTriangleMesh([
        SectionVector3(-1, 0, -1),
        SectionVector3(1, 0, 1),
        SectionVector3(0, 1, 1),
      ]);
      final result = clipper.clip(
        mesh: mesh,
        planePoint: const SectionVector3(0, 0, 0),
        planeNormal: const SectionVector3(0, 0, 1),
      );
      expect(result.surface.vertices.length, 6);
      expect(result.cutSegments.length, 1);
      for (final point in result.cutSegments.single) {
        expect(point.z.abs(), lessThan(1e-7));
      }
    });


    test('stitches unordered segments into a closed contour', () {
      const a=SectionVector3(0,0,0), b=SectionVector3(1,0,0);
      const c=SectionVector3(1,1,0), d=SectionVector3(0,1,0);
      final loops=AnatomyCrossSectionGeometry.stitchContours([
        [c,d], [a,b], [d,a], [b,c],
      ]);
      expect(loops, hasLength(1));
      expect(loops.single, hasLength(4));
    });

    test('triangulates a concave cap polygon', () {
      const polygon=[
        SectionVector3(0,0,0), SectionVector3(2,0,0),
        SectionVector3(2,2,0), SectionVector3(1,1,0),
        SectionVector3(0,2,0),
      ];
      final cap=AnatomyCrossSectionGeometry.triangulateCap(
        polygon, const SectionVector3(0,0,1));
      expect(cap.vertices, hasLength(9));
    });

    test('rejects a zero plane normal', () {
      expect(
        () => clipper.clip(
          mesh: const SectionTriangleMesh([]),
          planePoint: const SectionVector3(0, 0, 0),
          planeNormal: const SectionVector3(0, 0, 0),
        ),
        throwsArgumentError,
      );
    });
  });
}
