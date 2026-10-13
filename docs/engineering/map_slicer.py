import os
from PIL import Image

def slice_master_map(image_path, output_folder, prefix):
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)
        
    img = Image.open(image_path)
    width, height = img.size
    
    # 4x4 Grid settings
    rows = 4
    cols = 4
    
    chunk_w = width // cols
    chunk_h = height // rows
    
    for r in range(rows):
        for c in range(cols):
            box = (c * chunk_w, r * chunk_h, (c + 1) * chunk_w, (r + 1) * chunk_h)
            chunk = img.crop(box)
            
            # Downscale to Roblox's optimal native maximum 1024 limit to keep detail crisp
            chunk = chunk.resize((1024, 1024), Image.Resampling.LANCZOS)
            
            chunk.save(os.path.join(output_folder, f"{prefix}_chunk_{r}_{c}.png"))
    print(f"Successfully generated 16 uncompressed tiles for {prefix} in: {output_folder}")

# Run for both your custom generated assets
slice_master_map("master_heightmap.png", "Roblox_Heightmap_Tiles", "heightmap")
slice_master_map("master_colormap.png", "Roblox_Colormap_Tiles", "colormap")
