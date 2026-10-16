# src/scripts/generate-prehistoric-maps.py
from pathlib import Path
import numpy as np
import cv2

# Illustrative synthetic samples, not georeferenced 110 Ma terrain.

def generate_noise_tile(width, height, scale, octaves, roughness, seed_offset):
    canvas = np.zeros((height, width), dtype=np.float32)
    np.random.seed(seed_offset)
    for o in range(octaves):
        freq = scale * (2 ** o)
        amp = roughness ** o
        x = np.linspace(0, freq, width)
        y = np.linspace(0, freq, height)
        X, Y = np.meshgrid(x, y)
        noise = np.sin(X + np.random.uniform(0, 100)) * np.cos(Y + np.random.uniform(0, 100))
        canvas += noise * amp
    return ((canvas - canvas.min()) / (canvas.max() - canvas.min()) * 255).astype(np.uint8)

def bake_isolated_quadrant_tile(tile_name, height_base, material_color, output):
    width, height = 2048, 2048

    # Generate beautifully blended, unique rock textures per quadrant zone
    tile_height = generate_noise_tile(width, height, scale=4.0, octaves=5, roughness=0.5, seed_offset=len(tile_name))
    tile_height = np.clip(tile_height.astype(np.float32) * 0.4 + height_base, 0, 255).astype(np.uint8)

    tile_color = np.zeros((height, width, 3), dtype=np.uint8)
    tile_color[:] = material_color # Assign structural Roblox texture colors

    cv2.imwrite(str(output / f"tethys_grid_{tile_name}_heightmap.png"), cv2.GaussianBlur(tile_height, (15, 15), 0))
    cv2.imwrite(str(output / f"tethys_grid_{tile_name}_colormap.png"), tile_color)
    print(f"📦 [Grid Baked] Exported modular sector pair: tethys_grid_{tile_name}")

def run_grid_pipeline(output):
    output.mkdir(parents=True, exist_ok=True)
    print("🎨 [Grid Matrix Initializing] Slicing Tethys topography maps into high-resolution modular tiles...")

    # 1. BAKE THE 4 MAIN LAND TILES (Each maps out a 4096 x 4096 Stud region inside Studio)
    bake_isolated_quadrant_tile("NW_Arnn_Ridge", height_base=160, material_color=(110, 115, 118), output=output) # Slate Grey Rock
    bake_isolated_quadrant_tile("NE_Sky_City_Hub", height_base=180, material_color=(43, 43, 43), output=output)   # Heavy Basalt Foundation
    bake_isolated_quadrant_tile("SW_First_Sort", height_base=90, material_color=(90, 120, 140), output=output)    # Sand/Sediment Shallows
    bake_isolated_quadrant_tile("SE_Lower_Tiers", height_base=40, material_color=(111, 148, 175), output=output)   # Coastal Shelf

    # 2. BAKE THE DETACHED STRATOVOLCANO CORE (The isolated Watcher island)
    bake_isolated_quadrant_tile("Watcher_Volcano", height_base=210, material_color=(25, 25, 25), output=output)    # Scorched Obsidian Core

    print("\n🚀 [GRID CHUNKS ENGAGED] Five sector pairs generated. Ready for step-by-step studio import pass.")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Generate synthetic authoring samples without importing Terrain")
    parser.add_argument("--output", type=Path, default=Path("output/heightmap-samples"))
    run_grid_pipeline(parser.parse_args().output)
