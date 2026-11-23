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
  const SectionTriangleMesh(this.vertices);
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

  List<List<SectionVector3>> get closedContours => AnatomyCrossSectionGeometry.stitchContours(cutSegments);
}

/// Clips triangles against a plane using Sutherland-Hodgman polygon clipping.
///
/// Intersections are linearly interpolated in model-local space. Each clipped
/// polygon is fan-triangulated; degenerate triangles are discarded. The
/// intersection segments are preserved for contour stitching/cap generation.
class _Point2 { final double x, y; const _Point2(this.x, this.y); }

class AnatomyCrossSectionGeometry {
  static const double _epsilon = 1e-8;


  static List<List<SectionVector3>> stitchContours(List<List<SectionVector3>> segments, {double tolerance = 1e-6}) {
    if (tolerance <= 0 || !tolerance.isFinite) throw ArgumentError('Invalid tolerance');
    String key(SectionVector3 p) => (p.x / tolerance).round().toString() + ':' + (p.y / tolerance).round().toString() + ':' + (p.z / tolerance).round().toString();
    final adjacency = <String,List<int>>{}, points = <String,SectionVector3>{};
    final used = List<bool>.filled(segments.length,false);
    for (var i=0;i<segments.length;i++) {
      if (segments[i].length != 2) continue;
      final a=key(segments[i][0]), b=key(segments[i][1]);
      if (a==b) continue;
      points.putIfAbsent(a,()=>segments[i][0]); points.putIfAbsent(b,()=>segments[i][1]);
      adjacency.putIfAbsent(a,()=>[]).add(i); adjacency.putIfAbsent(b,()=>[]).add(i);
    }
    final loops=<List<SectionVector3>>[];
    for (var s=0;s<segments.length;s++) {
      if (used[s] || segments[s].length!=2) continue;
      final start=key(segments[s][0]); var current=key(segments[s][1]);
      final contour=<SectionVector3>[points[start]!,points[current]!]; used[s]=true;
      var closed=false;
      for (var guard=0;guard<=segments.length;guard++) {
        if (current==start) { closed=true; break; }
        int? next;
        for (final candidate in adjacency[current] ?? const <int>[]) { if (!used[candidate]) { next=candidate; break; } }
        if (next==null) break;
        used[next]=true; final seg=segments[next]; final a=key(seg[0]), b=key(seg[1]);
        current=a==current?b:a;
        if (current!=start) contour.add(points[current]!);
      }
      if (closed && contour.length>=3) loops.add(List.unmodifiable(contour));
    }
    return List.unmodifiable(loops);
  }

  static SectionTriangleMesh triangulateCap(List<SectionVector3> contour, SectionVector3 planeNormal) {
    if (contour.length<3) return const SectionTriangleMesh([]);
    final n=planeNormal.normalized();
    final helper=n.x.abs()<0.8?const SectionVector3(1,0,0):const SectionVector3(0,1,0);
    final u=SectionVector3(n.y*helper.z-n.z*helper.y,n.z*helper.x-n.x*helper.z,n.x*helper.y-n.y*helper.x).normalized();
    final v=SectionVector3(n.y*u.z-n.z*u.y,n.z*u.x-n.x*u.z,n.x*u.y-n.y*u.x);
    final origin=contour.first;
    final pts=contour.map((p){final d=p-origin;return _Point2(d.dot(u),d.dot(v));}).toList();
    double cross(_Point2 a,_Point2 b,_Point2 c)=>(b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x);
    var area=0.0;
    for(var i=0;i<pts.length;i++){final a=pts[i],b=pts[(i+1)%pts.length];area+=a.x*b.y-b.x*a.y;}
    if(area.abs()<_epsilon)return const SectionTriangleMesh([]);
    final orient=area>0?1.0:-1.0, indices=List<int>.generate(pts.length,(i)=>i);
    final out=<SectionVector3>[];
    bool inside(_Point2 p,_Point2 a,_Point2 b,_Point2 c)=>cross(a,b,p)*orient>=-_epsilon&&cross(b,c,p)*orient>=-_epsilon&&cross(c,a,p)*orient>=-_epsilon;
    var guard=pts.length*pts.length;
    while(indices.length>3&&guard-->0){
      var found=false;
      for(var i=0;i<indices.length;i++){
        final prev=indices[(i-1+indices.length)%indices.length],curr=indices[i],next=indices[(i+1)%indices.length];
        if(cross(pts[prev],pts[curr],pts[next])*orient<=_epsilon)continue;
        var contains=false;
        for(final k in indices){if(k==prev||k==curr||k==next)continue;if(inside(pts[k],pts[prev],pts[curr],pts[next])){contains=true;break;}}
        if(contains)continue;
        out.addAll([contour[prev],contour[curr],contour[next]]);indices.removeAt(i);found=true;break;
      }
      if(!found)return const SectionTriangleMesh([]);
    }
    if(indices.length==3)out.addAll(indices.map((i)=>contour[i]));
    return SectionTriangleMesh(List.unmodifiable(out));
  }

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
