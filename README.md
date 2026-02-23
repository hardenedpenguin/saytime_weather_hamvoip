# Saytime Weather for Hamvoip

A Ruby implementation of time and weather announcements for Asterisk on **Hamvoip** (and other non-Debian setups). Uses `/var/lib/asterisk/sounds` and supports both **gsm** and **ulaw** sound files. No API keys required; weather from Open-Meteo and NWS.

Based on [saytime_weather_rb](https://github.com/hardenedpenguin/saytime_weather_rb), adapted for Hamvoip: no Debian-specific paths (`sounds/en`), gsm as default with ulaw fallback for mixed installs.

## Requirements

- Ruby 2.7+
- Asterisk PBX (tested with versions 16+)
- Internet connection for weather API access
- Sound files under `/var/lib/asterisk/sounds` (gsm and/or ulaw)

## Installation

### Install script (recommended)

POSIX-compliant script that fetches the latest files from GitHub and installs to `/usr/sbin` (root:root, 755). Backs up existing `/etc/asterisk/local/weather.ini` to `weather.ini.bak` and installs a fresh default config.

```bash
curl -sL https://raw.githubusercontent.com/hardenedpenguin/saytime_weather_hamvoip/main/install.sh | sudo sh
```

Or with wget:

```bash
wget -qO- https://raw.githubusercontent.com/hardenedpenguin/saytime_weather_hamvoip/main/install.sh | sudo sh
```

### Manual install

Clone the repository and install the scripts (e.g. into `/usr/sbin` or run from the clone):

```bash
git clone git@github.com:hardenedpenguin/saytime_weather_hamvoip.git
cd saytime_weather_hamvoip
sudo cp saytime.rb weather.rb /usr/sbin/
sudo chmod +x /usr/sbin/saytime.rb /usr/sbin/weather.rb
sudo mkdir -p /etc/asterisk/local
sudo cp weather.ini.default /etc/asterisk/local/weather.ini
```

Ensure `weather.rb` and `saytime.rb` stay in the same directory so `saytime.rb` can find `weather.rb`.

## Configuration

The configuration file is at `/etc/asterisk/local/weather.ini`:

```ini
[weather]
Temperature_mode = F
process_condition = YES
default_country = us
weather_provider = openmeteo
show_precipitation = NO
show_wind = NO
show_pressure = NO
show_humidity = NO
show_zero_precip = NO
precip_trace_mm = 0.10
```

### Basic Options

- **Temperature_mode**: `F` for Fahrenheit or `C` for Celsius (default: `F`)
- **process_condition**: `YES` to process weather conditions, `NO` to skip (default: `YES`)
- **default_country**: ISO country code for postal code lookups (default: `us`)
- **weather_provider**: `openmeteo` for worldwide or `nws` for US only (default: `openmeteo`)

### Additional Weather Data

- **show_precipitation**: `YES` to show precipitation (default: `NO`)
- **show_wind**: `YES` to show wind speed and direction (default: `NO`)
- **show_pressure**: `YES` to show barometric pressure (default: `NO`)
- **show_humidity**: `YES` to show relative humidity (default: `NO`)
- **show_zero_precip**: `YES` to show precipitation when zero (default: `NO`)
- **precip_trace_mm**: Minimum precipitation threshold in mm (default: `0.10`)

Units follow `Temperature_mode` (F → mph, in, inHG; C → km/h, mm, hPa).

## Usage

### Weather Script

```bash
sudo /usr/sbin/weather.rb <location>
```

Examples:

```bash
sudo /usr/sbin/weather.rb 75001                    # US postal code
sudo /usr/sbin/weather.rb DFW                      # IATA airport code (3 letters)
sudo /usr/sbin/weather.rb KDFW                     # ICAO airport code (4 letters)
sudo /usr/sbin/weather.rb --default-country fr 75001
sudo /usr/sbin/weather.rb 75001 v                  # Display text only (verbose)
```

Options: `-d, --default-country CC`, `-c, --config FILE`, `-t, --temperature-mode M`, `--no-condition`, `-v, --verbose`, `-h, --help`

### Time Script

```bash
sudo /usr/sbin/saytime.rb -l <location_id> -n <node_number> [options]
```

Examples:

```bash
sudo /usr/sbin/saytime.rb -l 75001 -n 123456       # Basic announcement
sudo /usr/sbin/saytime.rb -l 75001 -n 123456 -u    # 24-hour format
sudo /usr/sbin/saytime.rb -l 75001 -n 123456 --no-weather  # Time only
TZ=UTC /usr/sbin/saytime.rb -l 75001 -n 123456 --no-weather  # UTC time
```

Required: `-l, --location_id=ID`, `-n, --node_number=NUM`

Common options: `-u, --use_24hour`, `-d, --default-country CC`, `-v, --verbose`, `--dry-run`, `--no-weather`

### When the announced time is in a timezone vs system local time

| Situation | What time is announced |
|-----------|------------------------|
| **`TZ` is set** (e.g. `TZ=UTC`, `TZ=Europe/London`) | Time in that timezone. `TZ` overrides everything. |
| **Weather on, location = postal code**, weather ran successfully | Time in the **location’s timezone** (from Open-Meteo or NWS; written to `/tmp/timezone` by `weather.rb`). |
| **Weather on, location = ICAO or IATA** (e.g. KDFW, JFK) | **System local time.** METAR/aviation APIs do not provide timezone, so no timezone file is written. |
| **`--no-weather`** | **System local time** (weather is not run, so no location timezone is available). |
| **Weather on but no valid timezone** (e.g. weather failed, or timezone file missing/invalid) | **System local time** (fallback). |

Summary: **Timezone is used** only when (1) you set `TZ`, or (2) weather is enabled, you pass a **postal code** (or location that resolves to coordinates), and `weather.rb` successfully gets weather from Open-Meteo or NWS and writes a timezone. **ICAO/IATA (airport codes) use system local time** because METAR does not supply timezone. All other cases announce **system local time**.

Run with `--help` for complete option list.

## Sound Files (Hamvoip)

- Sounds are read from **/var/lib/asterisk/sounds** (no `sounds/en` subdir).
- Both **.gsm** and **.ulaw** are supported; the script looks for the requested path, then the other extension, then under `sounds/wx` for weather conditions.
- Weather/temperature prompts are generated under `/tmp` and combined with system sounds for playback.

## Scheduled Announcements

```bash
# Top of each hour, 6 AM–11 PM
0 6-23 * * * /usr/sbin/saytime.rb -l 75001 -n 123456
```

## Links

- **Repository**: https://github.com/hardenedpenguin/saytime_weather_hamvoip
- **Upstream (Debian package)**: https://github.com/hardenedpenguin/saytime_weather_rb
- **License**: GPL-3+

## Maintainer

Jory A. Pratt (W5GLE) <geekypenguin@gmail.com>
