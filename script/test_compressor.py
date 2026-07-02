#!/usr/bin/env python3
#
# test_compressor.py
#
# Send one atomic Modbus command to the compressor, then continuously
# monitor telemetry until Ctrl+C.
#
# Usage:
#
#   python test_compressor.py 50
#
# where 50 is the requested power percentage (0-100).
#
# RPM = Power * 45
#

import argparse
import os
import sys
import time
from datetime import datetime

import pymodbus
from pymodbus.client import ModbusSerialClient

# ---------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------

PORT = "/dev/serial0"
DEVICE_ID = 1

BAUDRATE = 9600
TIMEOUT = 1.0

# Manual register numbers - 1
CONTROL_REGISTER = 1000
STATUS_REGISTER = 2000

RPM_PER_PERCENT = 45

# ---------------------------------------------------------------------
# Fault decoding
# ---------------------------------------------------------------------

FAULT1_BITS = {
    0: "Short Circuit",
    1: "Motor Stalled",
    2: "Module NTC Error",
    3: "Module Over Temperature",
    4: "Bus Over Voltage",
    5: "Bus Low Voltage",
    6: "Output Phase Lost",
    7: "Input Phase Lost",
    8: "Overload",
    9: "Communication Failure",
    10: "Bus Unbalance",
    11: "AC Low",
    12: "AC High",
    13: "External Fault",
    14: "EEPROM Error",
    15: "Internal Communication Failure",
}

FAULT2_BITS = {
    0: "Ambient Over Temperature Shutdown",
    1: "Ambient NTC Error",
    2: "External NTC Error",
    3: "Current Sample Error",
}

WARNING1_BITS = {
    0: "EEPROM Error",
    1: "Over Temperature Fast Down",
    2: "Over Temperature Slow Down",
    3: "Over Temperature Limit",
    4: "Analog Input Error",
    5: "Overload",
    6: "Communication Failure",
    7: "Ambient Over Temperature",
    8: "Fan Failure",
    9: "External NTC Error",
}


def decode_bits(value, table):
    active = []
    for bit, text in table.items():
        if value & (1 << bit):
            active.append(text)
    return active


# ---------------------------------------------------------------------
# Modbus
# ---------------------------------------------------------------------

client = ModbusSerialClient(
    port=PORT,
    baudrate=BAUDRATE,
    bytesize=8,
    parity="N",
    stopbits=1,
    timeout=TIMEOUT,
)

read_errors = 0
write_errors = 0
reads = 0


def send_command(power):

    global write_errors

    rpm = power * RPM_PER_PERCENT

    values = [
        0,              # Communication mode
        1 if power else 0,
        rpm,
    ]

    result = client.write_registers(
        address=CONTROL_REGISTER,
        values=values,
        device_id=DEVICE_ID,
    )

    if result is None or result.isError():
        write_errors += 1
        print("Command failed:", result)
        return False

    return True


def read_status():

    global reads
    global read_errors

    result = client.read_holding_registers(
        address=STATUS_REGISTER,
        count=9,
        device_id=DEVICE_ID,
    )

    if result is None or result.isError():
        read_errors += 1
        return None

    reads += 1

    return result.registers


# ---------------------------------------------------------------------
# Display
# ---------------------------------------------------------------------

def print_bitfield(title, value, table):

    print(f"{title:<12}: 0x{value:04X}")

    active = decode_bits(value, table)

    if active:
        for item in active:
            print(f"   • {item}")
    else:
        print("   None")


def dashboard(power):

    rpm_set = power * RPM_PER_PERCENT

    while True:

        regs = read_status()

        os.system("clear")

        print("=" * 60)
        print("Compressor Test")
        print("=" * 60)
        print()

        print(f"Port            : {PORT}")
        print(f"Device ID       : {DEVICE_ID}")
        print(f"pymodbus        : {pymodbus.__version__}")
        print(f"Time            : {datetime.now():%H:%M:%S}")
        print()

        print(f"Power           : {power}%")
        print(f"Setpoint        : {rpm_set} RPM")
        print()

        if regs is None:

            print("No response from compressor.\n")

            print(f"Reads           : {reads}")
            print(f"Read Errors     : {read_errors}")
            print(f"Write Errors    : {write_errors}")

            time.sleep(1)
            continue

        actual = regs[0]
        delta = actual - rpm_set

        print(f"Measured RPM    : {actual}")
        print(f"Tracking Δ      : {delta:+d} RPM")
        print()

        print(f"Bus Voltage     : {regs[5]} V")
        print(f"Output Current  : {regs[6] / 100:.2f} A")
        print(f"Ambient Temp    : {regs[7] / 10:.1f} °C")
        print(f"Module Temp     : {regs[8] / 10:.1f} °C")
        print()

        print_bitfield("Fault1", regs[1], FAULT1_BITS)
        print()

        print_bitfield("Fault2", regs[2], FAULT2_BITS)
        print()

        print_bitfield("Warning1", regs[3], WARNING1_BITS)
        print()

        print(f"Warning2   : 0x{regs[4]:04X}")

        if regs[4]:
            print("   Manufacturer specific")
        else:
            print("   None")

        print()
        print("-" * 60)
        print(f"Reads        : {reads}")
        print(f"Read Errors  : {read_errors}")
        print(f"Write Errors : {write_errors}")

        time.sleep(1)


# ---------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------

def main():

    parser = argparse.ArgumentParser(
        description="Compressor Modbus Test"
    )

    parser.add_argument(
        "power",
        type=int,
        help="Power percentage (0-100)"
    )

    args = parser.parse_args()

    if args.power < 0 or args.power > 100:
        print("Power must be between 0 and 100.")
        sys.exit(1)

    rpm = args.power * RPM_PER_PERCENT

    print(f"Connecting to {PORT}...")

    if not client.connect():
        print("Unable to open serial port.")
        sys.exit(1)

    print("Connected.")

    print()
    print("Sending command")
    print("----------------")
    print(f"Power    : {args.power}%")
    print(f"RPM      : {rpm}")

    if not send_command(args.power):
        client.close()
        sys.exit(1)

    print("Command accepted.")
    time.sleep(0.5)

    try:
        dashboard(args.power)

    except KeyboardInterrupt:
        print("\nStopping...")

    finally:
        client.close()


if __name__ == "__main__":
    main()
