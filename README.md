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
* **Web Framework:** Rails 8.1 (Configured for strict memory optimization)
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
The Rails application is executed with strict environment heap throttles to force Ruby to aggressively release unreferenced memory pages back to the Linux OS. The `kelvin-backend` service sets both (step 5 of Deployment):
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

A fresh Pi, from the SD card to the board on the TV. The commands run as the Pi's own user, with the app checked out in `~/kelvin`.

### 1. Raspberry Pi OS
Flash **Raspberry Pi OS Lite (64-bit)** with Raspberry Pi Imager, setting the user, Wi-Fi and SSH there. Then in `sudo raspi-config`:
* **Localisation Options → Timezone:** the board and admin show times in the Pi's time zone.
* **System Options → Boot / Auto Login → Console Autologin:** logs in on the Pi's screen at boot, which starts the kiosk (step 6).

And give the GPU as little memory as it will take, with `gpu_mem=16` in `/boot/firmware/config.txt` (see Memory Throttling above).

### 2. Packages
```bash
sudo apt update
sudo apt install -y git curl gpg build-essential libvips-tools fonts-noto-color-emoji cage cog
```
* `build-essential`: compiles Ruby, and the gems that need it, like bcrypt for the admin logins.
* `libvips-tools`: libvips, which resizes drink images.
* `fonts-noto-color-emoji`: so the kiosk can draw the drinks' emoji.
* `cage` and `cog`: the kiosk. Cage is a Wayland compositor that shows a single app full screen, and Cog is the WPE WebKit browser it shows.

### 3. Ruby
Ruby 3.4.9 through RVM, compiled one job at a time so it fits in 512MB, which takes a while:
```bash
gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
rvm install 3.4.9 -j 1
echo "gem: --no-document" >> ~/.gemrc
```
The last line skips installing gem documentation, saving disk space and writes to the SD card.

### 4. The app
```bash
git clone https://github.com/ajhewitt/kelvin.git ~/kelvin
cd ~/kelvin
bundle install
```

Copy `config/master.key` into `~/kelvin/config/`. It isn't in git: it unlocks `config/credentials.yml.enc`, which holds the key the app signs its logins with, so keep a copy somewhere safe. Without it, the server stops at boot with `` Missing `secret_key_base` ``.

Then set up the production database, build the assets, and add a login for the admin (it asks for a username and password):
```bash
RAILS_ENV=production bin/rails db:prepare
RAILS_ENV=production bin/rails assets:precompile
RAILS_ENV=production bin/rails users:create
```
`db:prepare` creates `storage/production.sqlite3` and fills a new one from `db/seeds.rb`: the hardware's configurations and sensors, and last year's board to start from.

**Every `bin/rails` command for the Pi needs `RAILS_ENV=production`.** Without it, a command like `bin/rails console` opens the development database, `storage/development.sqlite3`, not the one the board uses.

### 5. Starting the server at boot
A systemd service, `kelvin-backend`, runs the server. Before each start it runs `db:prepare`, which creates or migrates the database, so a fresh install or an update can't leave the server without its tables. This writes the service with your user and paths filled in, then starts it and has it start at every boot:
```bash
sudo tee /etc/systemd/system/kelvin-backend.service > /dev/null <<EOF
[Unit]
Description=Kelvin tap list board and admin
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/kelvin
Environment=RAILS_ENV=production MALLOC_ARENA_MAX=2
ExecStartPre=$HOME/.rvm/wrappers/ruby-3.4.9/bundle exec rails db:prepare
ExecStart=$HOME/.rvm/wrappers/ruby-3.4.9/bundle exec rails server -b 0.0.0.0
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now kelvin-backend
```
RVM's wrapper sets up Ruby the way a login shell would; `ls ~/.rvm/wrappers/ruby-3.4.9/bundle` shows it's there. Rails takes a minute or so to start on the Pi. Then `curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000/up` prints `200`, and the board is at `http://<Pi's address>:3000` (`hostname -I` shows the address).

### 6. The kiosk
Console autologin (step 1) logs in on the Pi's screen at boot. These lines at the end of `~/.bashrc` turn that login into the board: they wait for the server, then open the board full screen in Cog.
```bash
# The kiosk: on the Pi's own screen (tty1) only, not over SSH, show the board once the server answers
if [ "$(tty)" = "/dev/tty1" ] && [ -z "$WAYLAND_DISPLAY" ]; then
  until curl -sf -o /dev/null http://localhost:3000/up; do sleep 2; done
  # Let Cage start without a keyboard or mouse plugged in
  export WLR_LIBINPUT_NO_DEVICES=1
  # -s lets Ctrl+Alt+F2 switch to a login prompt
  cage -s -- cog http://localhost:3000
fi
```

### Updating
```bash
cd ~/kelvin
git pull
bundle install
RAILS_ENV=production bin/rails assets:precompile
sudo systemctl restart kelvin-backend
```
Restarting the service migrates the database. If an update brings a new system package, step 2's `apt install` is safe to re-run.

### Troubleshooting
* **Is the server answering?** `curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000/up` prints `200` when it is. The kiosk waits for it, so a blank screen at boot usually means the server hasn't started.
* **Why didn't it start?** `systemctl status kelvin-backend`, and `journalctl -u kelvin-backend -b --no-pager | tail -50` for its output. Or stop the service and run the server by hand, which prints why it stops:
  ```bash
  sudo systemctl stop kelvin-backend
  cd ~/kelvin && RAILS_ENV=production MALLOC_ARENA_MAX=2 bin/rails s -b 0.0.0.0
  ```
* **What its errors mean:**
  * `Could not find table …`: the production database isn't set up or migrated. Run `RAILS_ENV=production bin/rails db:prepare`.
  * `Could not find … in locally installed gems`: run `bundle install`.
  * `` Missing `secret_key_base` ``: `config/master.key` is missing (step 4).
  * Drink images missing, or `Could not open library 'vips.so.42'` in the log: run `sudo apt install libvips-tools`.

### 🍺 Admin
The board at `/` is public, for the TV. Everything else is behind a login at `/login`, which opens on the list for the event the board is showing. The sidebar has three sections, with **Users** at the bottom by logging out.

**Tap list**

* **Current list:** everything for the night in one place. Start and stop the event's serving session, and turn its draft temperature up or down a degree at a time, with the latest reading beside it. Below that are the event's drinks, laid out like the board. Kick a drink (it stays on the board, crossed out), move drinks up and down within their brand, move whole brands, set an emoji or hide a drink's image, and add or take off drinks. The board picks up changes within a minute.
* **Events:** date, name, tagline, which stats the board shows (SRM, IBU, ABV) and the board's theme. **Themes** previews all 18 on the event's board, from Classic (the original look) to Public House, Racing Green, Tudor and the rest. Each is a stylesheet in `app/assets/stylesheets/themes`, with its fonts bundled so the kiosk needs no internet.
* **Drinks:** name, brand (blank for the house's own), ABV, IBU, SRM, description and image. When a beer comes back with different numbers, use **Copy as new brew** so earlier events keep theirs.
* **Brands and Packages:** package sizes are typed as printed (12 oz, 660 ml, 5 gal, 4.5 imp gal).

**Refrigeration:** the configurations, sessions, sensors and actuators the hardware runs on. A sensor or actuator's type is the class that drives it, one to a file in `app/models` (`one_wire_sensor.rb`, `pwm_actuator.rb` and so on).

A session's form picks only its configuration. The serving session (the configuration with the slug `service`) is the one kind that's for an event, one to an event, so its form also offers the event. A session's status and times change only with **Start** and **Stop** on its page. Start runs a pending or stopped session; Stop stops a running one, and stopping a stopped session completes it, after which it can't be started again. The start time is stamped as a session leaves pending and the end time as it completes. The event's **Current list** has the same controls for its serving session.

A session holds **settings**, each a key and a number, which its configuration gives it. They show on its page with − and + buttons and the latest reading from the sensor with the same slug, and a key ending in `_temp` shows in °F. A serving session gets `draft_temp`, 38°F to start, which the event's list shows too. What the actuators do when a reading and its setting differ is still to come.

**Logs:** the sensor readings and control actions the hardware writes, newest first and read-only. Filter them by time, value, sensor or session; a sensor, actuator or session links to its own.

Times show in the Pi's time zone (`sudo raspi-config`, then restart the server), and are stored in UTC.

The admin screens are [Madmin](https://github.com/excid3/madmin) resources in `app/madmin/resources`, with the list page in `app/controllers/madmin/drink_packages_controller.rb`.

### 📌 Raspberry Pi 16-Pin Assignment Layout (BCM Mapping)

This table mirrors the physical layout of the first 16 pins on the Raspberry Pi header. Even-numbered pins are on the right (outer edge), and odd-numbered pins are on the left (inner edge).

| Left Column (Odd Pins) | Pin # | Pin # | Right Column (Even Pins) |
| :--- | :---: | :---: | :--- |
| **3.3V Power** <br> ➡️ *Shifter LV Ref & Sensors* | **01** | **02** | **5V Power** <br> ➡️ *Temp Sensors* |
| **GPIO 2** (SDA) <br> ⬅️ `temp0..3` *[1-Wire Bus]* | **03** | **04** | **5V Power** <br> ➡️ *Shifter HV Reference* |
| **GPIO 3** (SCL) <br> ⬅️ `flow_rate` *[Direct 3.3V Input]* | **05** | **06** | **Ground** <br> ➡️ *Common System Ground* |
| **GPIO 4** (GPCLK0) <br> 🔄`fan_speed` *[Direct 3.3V to MOSFET]* | **07** | **08** | **GPIO 14** (TXD0) <br> ➡️ `chiller_tx` *[Shifter CH2]* |
| **Ground** <br> ➡️ *Common System Ground* | **09** | **10** | **GPIO 15** (RXD0) <br> ⬅️ `chiller_rx` *[Shifter CH3]* |
| **GPIO 17** <br> ➡️ `pump_power` *[Direct 3.3V to MOSFET]* | **11** | **12** | **GPIO 18** (PWM0) <br> ➡️ `pump_speed` *[Shifter CH4]* |

---

### ⚙️ Hardware Connection & Logic Reference

* **Shifter Allocation (SparkFun 4-Channel):**
  * **CH1:** NC
  * **CH2:** Pin 8 (`GPIO 14`) ➡️ 3.3V to 5V TX signal to chiller microcontroller.
  * **CH3:** Pin 10 (`GPIO 15`) ⬅️ 5V to 3.3V RX signal from chiller microcontroller.
  * **CH4:** Pin 12 (`GPIO 18`) ➡️ 3.3V to 5V PWM signal to feed the analog filter.
* **Analog Speed Conversion 1:** The 5V PWM output exiting Shifter CH4 passes through a **10 kΩ series resistor** and **15 μF ceramic capacitor** shunt-to-ground to provide the true 0–5V analog voltage required by the Fortior FU6832S motor controller pin (P3.4).
* **Analog Speed Conversion 2:** A 3.3V software driven PWM output is used to switch a power MOSFET to drive the condenser fans utilizing a **SF24G flyback diode** and **330 μF electrolytic capacitor** shunt for smoothing.
* **Pull-up Resistors:** Pins 7, 15, and 16 use dual **10 kΩ pull-up resistor** in parallel tied to the 3.3V rail (Pin 1) to establish stable 1-Wire communication.

#### SCHEMATIC

```
     o--[24-USB]----o--<24v            (1kRES-3v3)/-GPIO2
     |              |                   4xTEMP>--{--5v
 GPIO7--[MOSFET]----o                   o---------\-SIG GND
     |  [CAP+.o]====+==<FAN+            |  [..>..]
     o--[330u.o]--o=+==<FAN-          /-+--[..<..]--GPIO14
     |            | |           TTY>-{--o--[SHIFT]==3v3,5v
GPIO17--[MOSFET]--+-o                 \----[..>..]--GPIO15
     |  [......]--+----[....CAP.o]--[RES]--[..<..]--GPIO18
     o--[......]--o----[....15u.o]   10k
     |            |    [.........]--\_/PUMP       /-3v3
    GND          GND   [PUMP DRVR]--/      FLOW>-{--GPIO3
    SIG          PWR   [.........]-/  (10kRES-3v3)\-GND
```

#### CHILLER HARNESS

```
PI-ZERO  <-- RIBBON |SHIFTER| JST --> CHILLER

(pin06)    GND (brn)-GND
(pin04)     5V (red)-----HV
(pin01) ** 3V3 (org)--LV GND-\
(pin08) GPIO14 (yel)-LV2 HV2--}-<MODBUS TTY
(pin10) GPIO15 (grn)-LV3 HV3-/
(pin12) GPIO18 (blu)-LV4 HV4-\
 ** PUMP SPEED (pur)--[RES]--/
```
