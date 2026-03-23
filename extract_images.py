import re
import base64
from pathlib import Path

# Path to HTML file
html_file = Path(__file__).parent / "index.html"
media_dir = Path(__file__).parent / "media"

# Create media directory if it doesn't exist
media_dir.mkdir(exist_ok=True)

# Read HTML content
with open(html_file, 'r', encoding='utf-8') as f:
    html_content = f.read()

# Pattern to find base64 images in src attributes
pattern = r'src="data:image/([^;]+);base64,([^"]+)"'

# Find all base64 images
matches = re.finditer(pattern, html_content)

# Dictionary to store mapping of base64 to filenames
image_mapping = {}
image_counter = {}

for match in matches:
    image_type = match.group(1)
    base64_data = match.group(2)
    full_data_uri = match.group(0)
    
    # Determine file extension
    ext = image_type if image_type in ['png', 'jpg', 'jpeg', 'gif'] else 'jpg'
    if ext == 'jpeg':
        ext = 'jpg'
    
    # Generate filename with counter
    image_type_clean = ext
    if image_type_clean not in image_counter:
        image_counter[image_type_clean] = 1
        filename = f"image-1.{ext}"
    else:
        image_counter[image_type_clean] += 1
        filename = f"image-{image_counter[image_type_clean]}.{ext}"
    
    # Decode base64 and save image
    try:
        image_data = base64.b64decode(base64_data)
        image_path = media_dir / filename
        with open(image_path, 'wb') as img_file:
            img_file.write(image_data)
        print(f"✓ Saved {filename}")
        image_mapping[full_data_uri] = f'src="media/{filename}"'
    except Exception as e:
        print(f"✗ Error saving {filename}: {e}")

# Replace all base64 src with file references
updated_html = html_content
for old_src, new_src in image_mapping.items():
    updated_html = updated_html.replace(old_src, new_src)

# Write updated HTML back
with open(html_file, 'w', encoding='utf-8') as f:
    f.write(updated_html)

print(f"\n✓ HTML updated successfully!")
print(f"✓ {len(image_mapping)} images extracted and saved to media folder")
