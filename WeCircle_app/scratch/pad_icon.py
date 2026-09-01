import os
import shutil
from PIL import Image

downloads_path = "/Users/fadimegali/Downloads/WhatsApp Image 2026-05-27 at 3.27.31 PM-Photoroom.png"
icon_path = "/Users/fadimegali/Desktop/project graduation/dashboard/Wesal_app/assets/images/app_icon.png"

if not os.path.exists(downloads_path):
    print(f"Error: Downloads path {downloads_path} not found.")
    exit(1)

# Ensure the destination directory exists
os.makedirs(os.path.dirname(icon_path), exist_ok=True)

# Copy the fresh original image first
shutil.copy(downloads_path, icon_path)

# Open image and convert to RGBA
img = Image.open(icon_path).convert("RGBA")

# Get bounding box of non-transparent content to crop out extra empty margins
bbox = img.getbbox()
if bbox:
    img = img.crop(bbox)

# Calculate target size (94% of 512 = 480px)
target_max_size = 480
width, height = img.size

# Maintain aspect ratio
if width > height:
    new_width = target_max_size
    new_height = int(height * (target_max_size / width))
else:
    new_height = target_max_size
    new_width = int(width * (target_max_size / height))

# Resize image
img_resized = img.resize((new_width, new_height), Image.Resampling.LANCZOS)

# Create a new transparent canvas (512x512)
new_img = Image.new("RGBA", (512, 512), (0, 0, 0, 0))

# Calculate center position
paste_x = (512 - new_width) // 2
paste_y = (512 - new_height) // 2

# Paste the logo
new_img.paste(img_resized, (paste_x, paste_y), img_resized)

# Save the padded icon back
new_img.save(icon_path, "PNG")
print("SUCCESS: App icon successfully padded to 94% size.")
