![](resources/gradient_with_rounded_transparency.png)

```python
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import random


def generate_random_color():
    return np.array([random.uniform(0.3, 0.9) * 255 for _ in range(3)], dtype=np.float32)

def generate_gaussian_mask(height, width, center_x, center_y, std_x, std_y):
    y = np.linspace(0, height - 1, height)
    x = np.linspace(0, width - 1, width)
    x, y = np.meshgrid(x, y)
    gaussian = np.exp(-(((x - center_x)**2) / (2 * std_x*2) + ((y - center_y)**2) / (2 * std_y*2)))
    return gaussian

def apply_blob_with_alpha(image, color, alpha_mask):
    for c in range(3): # RGB channels
        image[:, :, c] = alpha_mask[:, :, 0] * color[c] + (1 - alpha_mask[:, :, 0]) * image[:, :, c]
    return image

def overlay_centered_text(pil_img, text, font_path=None, font_size=100):
    draw = ImageDraw.Draw(pil_img)
    try:
        font = ImageFont.truetype(font_path, font_size) if font_path else ImageFont.load_default(font_size)
    except Exception as e:
        print(f"Warning: Failed to load font. Using default. Error: {e}")
        font = ImageFont.load_default(font_size)

    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    img_width, img_height = pil_img.size
    position = ((img_width - text_width) // 2, (img_height - text_height) // 2)
    draw.text(position, text, font=font, fill=(255, 255, 255))
    return pil_img

def generate_rounded_edge_alpha_mask(height, width, border_px=30, radius=30):
    """
    Creates an alpha mask with:
    - Transparent border of size border_px
    - Rounded corners with radius radius
    """
    # Start with fully transparent mask
    mask = Image.new('L', (width, height), 0)
    draw = ImageDraw.Draw(mask)

    # Define rectangle box for opaque area (inset by border_px)
    rect = [border_px, border_px, width - border_px, height - border_px]

    # Draw rounded rectangle filled white (opaque)
    draw.rounded_rectangle(rect, radius=radius, fill=255)
    return np.array(mask)

def generate_soft_gaussian_gradient(
    width=1080,
    height=1920,
    num_blobs=5,
    text=None,
    font_path=None,
    font_size=100,
    output_path="gradient_with_transparent_edges.png"
    ):

    image = np.ones((height, width, 3), dtype=np.float32) * 255
    for _ in range(num_blobs):
        center_x = random.randint(0, width)
        center_y = random.randint(0, height)
        std_x = random.uniform(10.2, 100.4) * width
        std_y = random.uniform(10.2, 100.4) * height
        color = generate_random_color()
        alpha_mask = generate_gaussian_mask(height, width, center_x, center_y, std_x, std_y)[..., np.newaxis]
        image = apply_blob_with_alpha(image, color, alpha_mask)

    # After gradient creation...
    image = np.clip(image, 0, 255).astype(np.uint8)

    # Add hard-edge transparency
    alpha_channel = generate_rounded_edge_alpha_mask(height, width, border_px=30, radius=30)
    rgba = np.dstack((image, alpha_channel))

    # Convert to RGBA image
    final_image = Image.fromarray(rgba, mode='RGBA')

    # Optional text
    if text:
        final_image = overlay_centered_text(final_image, text, font_path, font_size)

    # Save image
    final_image.save(output_path)

    print(f"Image with transparent rounded edges saved to {output_path}")

# Example usage
generate_soft_gaussian_gradient(
    width=1920,
    height=600,
    num_blobs=5,
    text="Gradient Love",
    font_path="Microsoft Sans Serif.ttf",
    font_size=250,
    output_path="gradient_with_rounded_transparency.png"
    )
```
