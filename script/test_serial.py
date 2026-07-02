import serial
import time

# Opens the primary Pi serial port at a default 9600 baud rate
ser = serial.Serial('/dev/serial0', baudrate=9600, timeout=1)

print("Sending data... Press Ctrl+C to stop.")
try:
    while True:
        ser.write(b'HELLO\n')
        incoming = ser.readline()
        if incoming:
            print(f"Received: {incoming}")
        time.sleep(1)
except KeyboardInterrupt:
    ser.close()
    print("\nTest stopped.")
