# FPGA Sobel Edge Detection
This project does real-time Sobel edge detection using a Basys-3 FPGA. A Python script sends a regular image to the FPGA over USB (UART), the FPGA calculates the edges, and sends the processed image back to the PC.

## Hardware Needed
* Xilinx Basys-3 FPGA (xc7s50)
* Micro-USB cable

## Files in this Repo
* `src/` - All the Verilog hardware files.
* `constraints/` - The pin mapping file for the Basys-3 board.
* `software/` - The Python script to send and receive images.

## How to Run It

**1. Setup the FPGA**
* Create a new project in Xilinx Vivado.
* Add the Verilog files (`.v`) as Design Sources and the constraints file (`.xdc`).
* Generate the bitstream and program your board.

**2. Run the Python Script**
* Install the required libraries on your PC:
  ```bash
  pip install pyserial numpy matplotlib pillow# Sobel-Edge-Detection
