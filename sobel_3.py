import serial
import time
import numpy as np
import matplotlib.pyplot as plt
import sys
import tkinter as tk
from tkinter import filedialog
from PIL import Image  # Requires: pip install Pillow

# --- CONFIGURATION ---
SERIAL_PORT = 'COM9' 
BAUD_RATE = 115200

# Dimensions must match Verilog parameters exactly
IMG_WIDTH = 256
IMG_HEIGHT = 256
IMG_SIZE = IMG_WIDTH * IMG_HEIGHT

def create_checkerboard():
    """Creates a 256x256 checkerboard image with a solid square."""
    img = np.zeros((IMG_HEIGHT, IMG_WIDTH), dtype=np.uint8)
    check_size = 32
    for y in range(IMG_HEIGHT):
        for x in range(IMG_WIDTH): # FIXED: Added missing colon here
            if ((x // check_size) + (y // check_size)) % 2 == 0:
                img[y, x] = 200 
            else:
                img[y, x] = 50  
    start = 96
    end = 160
    img[start:end, start:end] = 255
    return img

def create_horizontal_bars():
    img = np.zeros((IMG_HEIGHT, IMG_WIDTH), dtype=np.uint8)
    bar_height = 32
    for y in range(IMG_HEIGHT):
        if (y // bar_height) % 2 == 0:
            img[y, :] = 255
        else:
            img[y, :] = 0
    return img

def create_vertical_bars():
    img = np.zeros((IMG_HEIGHT, IMG_WIDTH), dtype=np.uint8)
    bar_width = 32
    for x in range(IMG_WIDTH):
        if (x // bar_width) % 2 == 0:
            img[:, x] = 255
        else:
            img[:, x] = 0
    return img

def create_diagonal_stripes():
    img = np.zeros((IMG_HEIGHT, IMG_WIDTH), dtype=np.uint8)
    period = 64
    for y in range(IMG_HEIGHT):
        for x in range(IMG_WIDTH):
            if ((x + y) // (period // 2)) % 2 == 0:
                img[y, x] = 255
            else:
                img[y, x] = 0
    return img

def create_circle():
    img = np.zeros((IMG_HEIGHT, IMG_WIDTH), dtype=np.uint8)
    center_x, center_y = IMG_WIDTH // 2, IMG_HEIGHT // 2
    radius = 80
    y, x = np.ogrid[:IMG_HEIGHT, :IMG_WIDTH]
    mask = (x - center_x)**2 + (y - center_y)**2 <= radius**2
    img[mask] = 255
    return img

def load_custom_image():
    """Opens a file dialog to load, grayscale, and resize a local image."""
    print("Opening file dialog...")
    # Initialize tkinter root but hide the main window
    root = tk.Tk()
    root.withdraw()
    root.attributes('-topmost', True) # Bring dialog to front

    file_path = filedialog.askopenfilename(
        title="Select an Image",
        filetypes=[("Image Files", "*.jpg;*.jpeg;*.png;*.bmp;*.tiff")]
    )
    
    # Destroy the root window after selection
    root.destroy() 

    if not file_path:
        print("No file selected.")
        return None

    try:
        # Open image
        img = Image.open(file_path)
        
        # 1. Convert to Grayscale ('L' mode)
        img = img.convert('L')
        
        # 2. Resize to 256x256 specifically for the FPGA
        # Use LANCZOS for high quality downsampling
        img = img.resize((IMG_WIDTH, IMG_HEIGHT), Image.Resampling.LANCZOS)
        
        # 3. Convert to Numpy array
        img_array = np.array(img, dtype=np.uint8)
        return img_array
        
    except Exception as e:
        print(f"Error processing image: {e}")
        return None

def get_pattern_choice():
    print("\n--- Select Test Pattern (256x256) ---")
    print("1. Checkerboard with Square")
    print("2. Horizontal Bars")
    print("3. Vertical Bars")
    print("4. Diagonal Stripes")
    print("5. Solid Circle")
    print("6. Upload Custom Image (JPG/PNG)")
    
    while True:
        choice = input("Enter choice (1-6): ")
        if choice in ['1', '2', '3', '4', '5', '6']:
            return choice
        print("Invalid choice. Please enter 1-6.")

def main():
    print(f"Opening Serial Port {SERIAL_PORT}...")
    try:
        # Timeout increased to 15s to be safe for 65k bytes
        ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=15)
        
        ser.dtr = False
        time.sleep(0.1)
        ser.dtr = True
        time.sleep(1) 
        
        choice = get_pattern_choice()
        
        original_img = None
        pattern_name = "Unknown"

        if choice == '1':
            original_img = create_checkerboard()
            pattern_name = "Checkerboard"
        elif choice == '2':
            original_img = create_horizontal_bars()
            pattern_name = "Horizontal Bars"
        elif choice == '3':
            original_img = create_vertical_bars()
            pattern_name = "Vertical Bars"
        elif choice == '4':
            original_img = create_diagonal_stripes()
            pattern_name = "Diagonal Stripes"
        elif choice == '5':
            original_img = create_circle()
            pattern_name = "Circle"
        elif choice == '6':
            original_img = load_custom_image()
            pattern_name = "Custom Image"
            if original_img is None:
                return # Exit if user cancelled or error
            
        img_bytes = original_img.tobytes()
        
        print(f"\nSending {len(img_bytes)} bytes ({pattern_name}) to FPGA...")
        print("This will take about 6 seconds at 115200 baud...")
        start_time = time.time()
        
        # 1. Send Image
        bytes_written = ser.write(img_bytes)
        print(f"Sent {bytes_written} bytes.")
        
        # 2. Read processed image back
        print("Waiting for response (approx 6 seconds)...")
        response_bytes = ser.read(IMG_SIZE)
        
        end_time = time.time()
        print(f"Received {len(response_bytes)} bytes in {end_time - start_time:.4f} seconds.")
        
        if len(response_bytes) != IMG_SIZE:
            print(f"Error: Expected {IMG_SIZE} bytes, but got {len(response_bytes)}.")
            print("Troubleshooting: Check connections or increase timeout if transfer is too slow.")
            return

        # 3. Reshape and Display
        processed_img = np.frombuffer(response_bytes, dtype=np.uint8).reshape((IMG_HEIGHT, IMG_WIDTH))
        
        # Plotting
        fig, ax = plt.subplots(1, 2, figsize=(10, 5))
        
        ax[0].imshow(original_img, cmap='gray', vmin=0, vmax=255)
        ax[0].set_title(f"Original: {pattern_name} (256x256)")
        ax[0].axis('off')
        
        ax[1].imshow(processed_img, cmap='gray', vmin=0, vmax=255)
        ax[1].set_title("Sobel Edge (FPGA Result)")
        ax[1].axis('off')
        
        plt.tight_layout()
        plt.show()
        
        ser.close()
        
    except serial.SerialException as e:
        print(f"Serial Error: {e}")
        print("Check if the Port is correct and the FPGA is plugged in.")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    main()