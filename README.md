# Kelvin

Kelvin is a bespoke brewery automation engine, taproom telemetry hub, and digital tap list manager. It runs on a heavily optimized, resource-constrained Raspberry Pi Zero 2 W (512MB RAM) running Raspberry Pi OS Lite.

The core system manages a reconfigurable industrial cooling solution alongside a clean web-based tap list display and administrative control panel.

---

## ⚙️ System Architecture & Hardware Specs

### 1. Thermal Control & Refrigeration
* **Primary Chiller:** Rigid Compact Liquid Chiller Module (Model: **DV3220E-C (24V)**).
* **Operation Modes:** 
  * *Service Mode:* Chills glycol loop exclusively for the draft tap system and cask.
  * *Brewing Mode:* Reconfigured to chill water reservoir for brewday wort cooling.
  * *Fermentation Mode:* Manages automated glycol loop distribution to fermentation tanks.
* **Control Interface:** UART interface communicating with the compressor control board using **Modbus RTU** commands.

### 2. Sensor Integration & Telemetry
* **Temperature Monitoring:** DS18B20 **1-Wire** digital sensors distributed across the fluid loops.
* **Fluid Dynamics:** Custom **PWM** signals driving the glycol/water loop circulation pump.
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
