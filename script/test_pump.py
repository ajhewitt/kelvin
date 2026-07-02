#!/usr/bin/env python3
#
# test_pump.py
#
# Control the circulation pump using:
#
#   GPIO17  -> Enable (opto-isolated MOSFET board)
#   GPIO18  -> Hardware PWM (speed command)
#   GPIO3   -> Hall-effect flow sensor
#
# Usage:
#
#   python test_pump.py 0      # Stop pump
#   python test_pump.py 50     # Run at 50%
#
# The power command is sent once. The script then continuously
# displays flow telemetry until Ctrl-C.
#

import argparse
import os
import signal
import sys
import time
from collections import deque
from datetime import timedelta

import pigpio

# ------------------------------------------------------------
# GPIO Configuration
# ------------------------------------------------------------

ENABLE_PIN = 17
PWM_PIN = 18
FLOW_PIN = 3

PWM_FREQUENCY = 1000      # Hz
PWM_RANGE = 1000000       # pigpio hardware PWM range

FLOW_CONSTANT = 7.5       # Hz = 7.5 * L/min

# ------------------------------------------------------------

pi = pigpio.pi()

if not pi.connected:
    print("Unable to connect to pigpio daemon.")
    print("Start it with:")
    print("    sudo pigpiod")
    sys.exit(1)

pulse_count = 0
total_pulses = 0

flow_history = deque(maxlen=5)

start_time = time.time()


# ------------------------------------------------------------
# Flow Sensor Callback
# ------------------------------------------------------------

def flow_callback(gpio, level, tick):
    global pulse_count
    global total_pulses

    pulse_count += 1
    total_pulses += 1


cb = pi.callback(FLOW_PIN, pigpio.RISING_EDGE, flow_callback)

# ------------------------------------------------------------
# Pump Control
# ------------------------------------------------------------

def pump_stop():

    pi.hardware_PWM(PWM_PIN, PWM_FREQUENCY, 0)
    pi.write(ENABLE_PIN, 0)


def pump_start(percent):

    duty = int(percent / 100.0 * PWM_RANGE)

    pi.write(ENABLE_PIN, 1)
    pi.hardware_PWM(PWM_PIN, PWM_FREQUENCY, duty)


# ------------------------------------------------------------
# Dashboard
# ------------------------------------------------------------

def dashboard(power):

    global pulse_count

    total_volume = 0.0

    while True:

        time.sleep(1)

        pulses = pulse_count
        pulse_count = 0

        frequency = float(pulses)
        flow = frequency / FLOW_CONSTANT

        total_volume += flow / 60.0

        flow_history.append(flow)

        average_flow = sum(flow_history) / len(flow_history)

        runtime = timedelta(seconds=int(time.time() - start_time))

        os.system("clear")

        print("=" * 60)
        print("Pump Test")
        print("=" * 60)
        print()

        print(f"Power Command : {power}%")

        if power == 0:
            print("Pump          : OFF")
        else:
            print("Pump          : RUNNING")

        print()
        print("Hydraulics")
        print("-" * 60)

        print(f"Frequency     : {frequency:6.1f} Hz")
        print(f"Flow Rate     : {flow:6.2f} L/min")
        print(f"5s Average    : {average_flow:6.2f} L/min")
        print(f"Total Volume  : {total_volume:6.2f} L")

        print()
        print("GPIO")
        print("-" * 60)

        print(f"Enable        : GPIO17 {'HIGH' if power else 'LOW'}")
        print(f"PWM           : GPIO18 @ {power}%")
        print(f"Flow Sensor   : GPIO3")

        print()
        print("Statistics")
        print("-" * 60)

        print(f"Runtime       : {runtime}")
        print(f"Pulse Count   : {total_pulses}")

        print()
        print("Press Ctrl-C to stop.")


# ------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------

def shutdown(signum=None, frame=None):

    print("\nStopping pump...")

    pump_stop()

    cb.cancel()

    pi.stop()

    print("Done.")

    sys.exit(0)


signal.signal(signal.SIGINT, shutdown)

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

def main():

    parser = argparse.ArgumentParser(
        description="Pump Test Utility"
    )

    parser.add_argument(
        "power",
        type=int,
        help="Pump power (0-100 %)"
    )

    args = parser.parse_args()

    if args.power < 0 or args.power > 100:
        print("Power must be between 0 and 100.")
        sys.exit(1)

    pi.set_mode(ENABLE_PIN, pigpio.OUTPUT)
    pi.set_mode(FLOW_PIN, pigpio.INPUT)

    if args.power == 0:
        pump_stop()
    else:
        pump_start(args.power)

    dashboard(args.power)


if __name__ == "__main__":
    main()
