# Atlas Anatomy Cross-Section Engine

## Status

This folder contains the first native shader asset for true plane clipping. It is not yet wired into the Android or iOS renderers, and the section engine must not be presented in the student app as complete until both native integrations and cap geometry are implemented and tested.

## Coordinate convention

The section plane is expressed in API-level model/world coordinates:

- `sectionPlaneNormal`: normalized XYZ normal.
- `sectionPlaneOffset`: signed plane distance in the same coordinate space.
- `sectionEnabled`: 0 disables clipping; 1 enables it.

The kept half-space is `dot(position, normal) - offset >= 0`.

## Filament material

`atlas_anatomy_section.mat` is the material-source prototype. Compile it with the exact Filament material compiler version and target APIs shipped by the Android plugin. Do not substitute a material package built against an arbitrary Filament release.

The runtime must create a material instance with these parameters and apply it to every relevant glTF primitive. Existing selection, texture, cache and PBR overrides must be composed rather than discarded.

## Required renderer integration

1. Generate a compatible .filamat asset in the Android build pipeline.
2. Add a section-plane method to the Flutter platform interface and method channel.
3. Apply the plane to every active model material instance and restore the original material instances when disabled.
4. Add the equivalent SceneKit shader modifier on iOS, using the same model-space plane convention.
5. Add a cap pass. Clipping alone leaves an open, hollow boundary; a cap must be generated from the intersection contours, triangulated, assigned an anatomical cut-surface material, and updated when the plane moves.
6. Handle skinned meshes, multiple primitives, nested transforms, glTF material variants, and model reload/disposal.
7. Add integration tests for all three planes, both signs, boundary positions, camera orbit, and repeated enable/disable.

## Important limitation

A fragment-discard shader alone is not a complete anatomical cross-section: it removes fragments but does not create the exposed cut face. The cap geometry is essential for a medically useful solid section view.
