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
            
            # Fixed preview tile size, not a claim about the Terrain import limit
            chunk = chunk.resize((1024, 1024), Image.Resampling.LANCZOS)
            
            chunk.save(os.path.join(output_folder, f"{prefix}_chunk_{r}_{c}.png"))
    print(f"Successfully generated 16 uncompressed tiles for {prefix} in: {output_folder}")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Split a supplied raster into sixteen authoring tiles")
    parser.add_argument("image")
    parser.add_argument("output")
    parser.add_argument("--prefix", default="map")
    args = parser.parse_args()
    slice_master_map(args.image, args.output, args.prefix)
