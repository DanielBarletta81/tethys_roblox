# Mac terrain and art pipeline

Keep environment authoring reproducible on the project's Mac workflow. Native Studio terrain and Blender are the baseline; a paid Blender terrain add-on can remain optional.

QuadSpinner currently documents Gaea as Windows-only and states Gaea 2 needs AVX2 unavailable in the macOS Parallels environment. It is not a required tool for this codebase. [QuadSpinner FAQ](https://quadspinner.com/FAQ).

Blender supports Apple Silicon; check the selected version's macOS requirements rather than assuming every Mac supports every release. [Blender requirements](https://www.blender.org/download/requirements/).

Export a terrain heightmap and optional colormap, then use **Roblox Terrain Editor -> Create -> Import** to apply them to a chosen region. Heightmap import belongs to Terrain Editor. Mesh assets use Roblox's 3D import workflow separately. Continue with native Sculpt, Smooth and Paint for playable details and caves. [Terrain Editor](https://create.roblox.com/docs/studio/terrain-editor), [3D importer](https://create.roblox.com/docs/art/modeling/3d-importer).

Record source, license, scale, orientation and export settings for terrain and models. Back up voxel regions before world edits, work in declared areas, and validate the actual Terrain collision and water surface. A photorealistic terrain render is not proof of navigable Roblox geometry.

For character imagery, preserve originals and use approved sanitized copies in the static menu preview. UI labels and interaction text stay native rather than embedded in screenshots. World of Tethys visual identity should support the environment and restrained HUD, while source art and original packs remain outside this public code portfolio.
