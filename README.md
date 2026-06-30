# Kelvin

Kelvin is an embedded application and presentation layer for a bespoke, reconfigurable refrigeration solution. Architected for deployment on the resource-constrained Raspberry Pi Zero 2 W (512MB RAM) running Raspberry Pi OS Lite, the system manages a compact vapor-phase refrigeration unit alongside a clean web-based tap list display and back-end administrative control panel.

Vibe-coded by Gemini (for free) using the Google search prompt in _AI Mode_

---

## ⚙️ System Architecture & Hardware Specs

### 1. Thermal Control & Refrigeration
* **Primary Chiller:** Rigid Compact Liquid Chiller Module (Model: **DV3220E-C**).
* **Operation Modes:** 
  * *Service Mode:* Chills glycol loop exclusively for the draft tap system and cask.
  * *Brewing Mode:* Reconfigured to chill water reservoir for brewday wort cooling.
  * *Fermentation Mode:* Manages automated glycol loop distribution to fermentation tanks.
* **Control Interface:** UART interface communicating with the compressor control board using **Modbus RTU** commands.

### 2. Sensor Integration & Telemetry
* **Temperature Monitoring:** DS18B20 **1-Wire** digital sensors distributed across the fluid reservoirs and loops.
* **Fluid Dynamics:** Custom **PWM** signals driving the glycol/water loop circulation pump, plus flow rate sensing.
* **Telemetry Cadence:** System status, hardware diagnostics, and thermal metrics are sampled and written to the database **once per minute**.

---

## 🛠️ Software Stack

* **Operating System:** Raspberry Pi OS Lite (64-bit, headless Debian base)
* **Compositor & Browser (Kiosk Mode):** Cage (Wayland kiosk compositor) + Cog (WPE WebKit browser engine)
* **Language Runtime:** Ruby 3.4.9 (Compiled single-threaded via RVM)
* **Web Framework:** Rails 8.1.3 (Configured for strict memory optimization)
* **Web Server:** Puma (Strict single-process, single-thread worker mode)
* **Database:** SQLite3

---

## 🔬 Memory Throttling & Pi Optimization

To run a modern Rails 8 application alongside a graphical WebKit browser on a **512MB RAM memory budget**, the following system overrides are implemented:

### 1. Kernel & Hardware Profile (`/boot/firmware/config.txt`)
The Raspberry Pi GPU memory is stripped down to the absolute bare minimum to give the CPU and Rails runtime maximum breathing room:
```text
gpu_mem=16
```

### 2. Production Puma Server Constraints (`config/puma.rb`)
Puma is locked out of multi-threaded or clustered worker clustering. It runs as a solitary process to clamp its memory footprint at rest:
```ruby
threads 1, 1
workers 0
```

### 3. Garbage Collection Tuning
The Rails application is executed with strict environment heap throttles to force Ruby to aggressively release unreferenced memory pages back to the Linux OS:
```bash
export MALLOC_ARENA_MAX=2
export RAILS_ENV=production
```

---

## 🛰️ Hardware Integration & Background Processing

### Background Telemetry Loop (Rake Task)
Hardware polling (Modbus RTU data packets, 1-Wire file scraping, and PWM calculation steps) is executed via a persistent, lightweight Ruby Rake task. This design keeps the telemetry layer native to the application codebase:

```bash
# To initiate the background hardware monitor daemon
RAILS_ENV=production bin/rails hardware:telemetry_loop
```

The task reads the physical system pins, interfaces with the Modbus communication registers, updates the core database tables once per minute, and updates the active serving temperatures shown on the frontend view layer.

---

## 🚀 Deployment & Installation

### Local Repository Preparation
1. Initialize the system package lists and ensure core compilation utilities are ready:
   ```bash
   sudo apt update && sudo apt install git curl gpg build-essential -y
   ```
2. Disable local documentation downloads to save disk space and write I/O:
   ```bash
   echo "gem: --no-document" >> ~/.gemrc
   ```
3. Install dependencies and initialize the database:
   ```bash
   bundle install --deployment
   RAILS_ENV=production bin/rails db:prepare
   RAILS_ENV=production bin/rails assets:precompile
   ```

### Running the Server
Launch the production instances explicitly bound to all network interfaces to allow external administrative oversight over your local network:
```bash
RAILS_ENV=production MALLOC_ARENA_MAX=2 bin/rails s -b 0.0.0.0
```

### 📌 Raspberry Pi 16-Pin Assignment Layout (BCM Mapping)

This table mirrors the physical layout of the first 16 pins on the Raspberry Pi header. Even-numbered pins are on the right (outer edge), and odd-numbered pins are on the left (inner edge).

| Left Column (Odd Pins) | Pin # | Pin # | Right Column (Even Pins) |
| :--- | :---: | :---: | :--- |
| **3.3V Power** <br> ➡️ *Shifter LV Ref & Sensors* | **01** | **02** | **5V Power** <br> ➡️ *Shifter HV Reference* |
| **GPIO 2** (SDA) <br> ⬅️ `temp0..3` *[1-Wire Bus]* | **03** | **04** | **5V Power** <br> ➡️ *Unused* |
| **GPIO 3** (SCL) <br> ⬅️ `flow_rate` *[Direct 3.3V Input]* | **05** | **06** | **Ground** <br> ➡️ *Common System Ground* |
| **GPIO 4** (GPCLK0) <br> 🔄 `comp_speed` *[Shifter CH3]* | **07** | **08** | **GPIO 14** (TXD0) <br> ➡️ `chiller_tx` *[Shifter CH1]* |
| **Ground** <br> ➡️ *Common System Ground* | **09** | **10** | **GPIO 15** (RXD0) <br> ⬅️ `chiller_rx` *[Shifter CH2]* |
| **GPIO 17** <br> ➡️ `pump_power` *[Direct 3.3V to MOSFET]* | **11** | **12** | **GPIO 18** (PWM0) <br> ➡️ `pump_speed` *[Shifter CH4]* |
| **GPIO 27** <br> ➡️ `fan_speed` *[Direct 3.3V to MOSFET]* | **13** | **14** | **Ground** <br> ➡️ *Common System Ground* |

---

### ⚙️ Hardware Connection & Logic Reference

* **Shifter Allocation (SparkFun 4-Channel):**
  * **CH1:** Pin 8 (`GPIO 14`) ➡️ 3.3V to 5V TX signal to chiller microcontroller.
  * **CH2:** Pin 10 (`GPIO 15`) ⬅️ 5V to 3.3V RX signal from chiller microcontroller.
  * **CH3:** Pin 7 (`GPIO 4`) ➡️ 3.3V to 5V clock signal as aux compresor speed control.
  * **CH4:** Pin 12 (`GPIO 18`) ➡️ 3.3V to 5V PWM signal to feed the analog filter.
* **Analog Speed Conversion 1:** The 5V PWM output exiting Shifter CH4 passes through a **10 kΩ series resistor** and **22 μF ceramic capacitor** shunt-to-ground to provide the true 0–5V analog voltage required by the Fortior FU6832S motor controller pin (P3.4).
* **Analog Speed Conversion 2:** A 3.3V software driven PWM output is used to switch a power MOSFET to drive the condenser fans utilizing a **SF24G flyback diode** and **330 μF electrolytic capacitor** shunt for smoothing.
* **Pull-up Resistors:** Pins 7, 15, and 16 use dual **10 kΩ pull-up resistor** in parallel tied to the 3.3V rail (Pin 1) to establish stable 1-Wire communication.

#### SCHEMATIC

```
     o--[24-USB]----o--<24v             4xTEMP>--{--GPIO2
     |              |                 (1kRES-3v3){--5v
GPIO27--[MOSFET]----o                {--o--------{--SIG GND
     |  [CAP+.o]====+==<FAN+  TTY>---{--+--[..>..]--GPIO14
     o--[330u.o]--o=+==<FAN-         {--+--[..<..]--GPIO15
     |            | |        COMP>---{--o--[SHIFT]==3v3,5v
GPIO17--[MOSFET]--+-o                {-----[..<..]--GPIO7
     |  [......]--+----[....CAP.o]--[RES]--[..<..]--GPIO18
     o--[......]--o----[....15u.o]   10k
     |            |    [.........]--}--<PUMP     {--3v3
    GND          GND   [PUMP DRVR]--}     FLOW>--{--GPIO3
    SIG          PWR   [.........]--}(10kRES-3v3){--GND
```

#### CHILLER HARNESS

```
PI-ZERO  <-- RIBBON |SHIFTER| JST --> CHILLER

(pin06)    GND (brn)-GND
(pin04)     5V (red)-----HV
(pin01) ** 3V3 (org)--LV GND-\
(pin08) GPIO14 (yel)-LV1 HV1--}-<MODBUS TTY
(pin10) GPIO15 (grn)-LV2 HV2-/
(pin07) GPIO 4 (blu)-LV3 HV3==}-<COMP SPEED
(pin12) GPIO18 (pur)-LV4 HV4-\
 ** PUMP SPEED (gry)--[RES]--/
```
