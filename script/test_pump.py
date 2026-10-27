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

#!/usr/bin/env python3

import argparse
import os
import signal
import sys
import time
from collections import deque
from datetime import timedelta

import lgpio

# ------------------------------------------------------------
# GPIO CONFIG
# ------------------------------------------------------------

GPIO_ENABLE = 17
GPIO_PWM = 18
GPIO_FLOW = 3

PWM_FREQ = 1000
FLOW_K = 7.5  # F = 7.5 * Q  => Q = F / 7.5

# ------------------------------------------------------------
# STATE
# ------------------------------------------------------------

pulse_count = 0
total_pulses = 0
flow_history = deque(maxlen=5)

start_time = time.time()

h = None  # gpio handle


# ------------------------------------------------------------
# FLOW CALLBACK
# ------------------------------------------------------------

def flow_callback(chip, gpio, level, tick):
    global pulse_count, total_pulses
    if level == 1:
        pulse_count += 1
        total_pulses += 1


# ------------------------------------------------------------
# PUMP CONTROL
# ------------------------------------------------------------

def pump_stop():
    lgpio.gpio_write(h, GPIO_ENABLE, 0)
    lgpio.tx_pwm(h, GPIO_PWM, PWM_FREQ, 0)


def pump_start(percent):
    duty = int(percent)

    lgpio.gpio_write(h, GPIO_ENABLE, 1)
    lgpio.tx_pwm(h, GPIO_PWM, PWM_FREQ, duty)


# ------------------------------------------------------------
# CLEAN SHUTDOWN
# ------------------------------------------------------------

shutdown_called = False

def shutdown(*_):
    global shutdown_called, h

    if shutdown_called:
        return

    shutdown_called = True

    print("\nStopping pump...")

    try:
        pump_stop()
    except Exception:
        pass

    try:
        cb.cancel()
    except Exception:
        pass

    try:
        if h is not None:
            lgpio.gpiochip_close(h)
    except Exception:
        pass

    print("Done.")

# ------------------------------------------------------------
# DASHBOARD
# ------------------------------------------------------------

def dashboard(power):

    global pulse_count

    total_liters = 0.0

    while True:

        time.sleep(1)

        pulses = pulse_count
        pulse_count = 0

        frequency = float(pulses)  # 1 second window
        flow = frequency / FLOW_K

        total_liters += flow / 60.0
        flow_history.append(flow)

        avg_flow = sum(flow_history) / len(flow_history)

        runtime = timedelta(seconds=int(time.time() - start_time))

        os.system("clear")

        print("=" * 60)
        print("Pump Test (lgpio)")
        print("=" * 60)
        print()

        print(f"Power Command : {power}%")
        print(f"Pump          : {'RUNNING' if power else 'OFF'}")
        print()

        print("Hydraulics")
        print("-" * 60)
        print(f"Frequency     : {frequency:6.1f} Hz")
        print(f"Flow Rate     : {flow:6.2f} L/min")
        print(f"5s Average    : {avg_flow:6.2f} L/min")
        print(f"Total Volume  : {total_liters:6.2f} L")
        print()

        print("GPIO")
        print("-" * 60)
        print(f"Enable        : GPIO17 {'HIGH' if power else 'LOW'}")
        print(f"PWM           : GPIO18 @ {power}%")
        print(f"Flow Input    : GPIO3")
        print()

        print("Statistics")
        print("-" * 60)
        print(f"Runtime       : {runtime}")
        print(f"Pulse Count   : {total_pulses}")
        print()
        print("Ctrl-C to stop.")


# ------------------------------------------------------------
# MAIN
# ------------------------------------------------------------

def main():

    global h

    parser = argparse.ArgumentParser()
    parser.add_argument("power", type=int, help="0-100 % pump power")
    args = parser.parse_args()

    if args.power < 0 or args.power > 100:
        print("Power must be 0–100")
        sys.exit(1)

    # open gpio chip
    h = lgpio.gpiochip_open(0)

    # configure pins
    lgpio.gpio_claim_output(h, GPIO_ENABLE)
    lgpio.gpio_claim_output(h, GPIO_PWM)

    lgpio.gpio_claim_input(h, GPIO_FLOW)

    # attach flow callback
    lgpio.callback(h, GPIO_FLOW, lgpio.RISING_EDGE, flow_callback)

    # start/stop pump
    if args.power == 0:
        pump_stop()
    else:
        pump_start(args.power)

    try:
        dashboard(args.power)
    except KeyboardInterrupt:
        shutdown()

if __name__ == "__main__":
    main()
