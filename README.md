# do-rec

## Description

`do-rec` is a versatile Bash script that automates audio recording using the `arecord` utility. It provides a variety of features, including scheduling, file splitting, custom output paths, and email notifications to keep you informed about session progress and errors.

The script is ideal for long-duration recordings, such as meetings, podcasts, or monitoring sessions, and can easily integrate with local or network storage solutions.

---

## Features

- **Automated Recording**: Leverages the `arecord` utility for audio recording.
- **Scheduling**: Supports start time scheduling for delayed recordings.
- **File Splitting**: Automatically splits recordings into smaller files for easier management.
- **Customizable Output Paths**: Save recordings locally or to a network drive.
- **Session Logging**: Generates detailed logs with recording session details.
- **Email Notifications**: Sends email alerts for session start, completion, and errors, using configurable email utilities.

---

## Requirements

### Audio Recording
- `arecord`: Ensure the ALSA sound utility is installed and configured.

### Email Notifications
One of the following email utilities must be installed and configured:
- `mutt`
- `mail` (or `mailx`)
- `sendmail`
- `msmtp`

---

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/<your-username>/do-rec.git
   cd do-rec
   ```

2. Move the script to a preferred location (e.g., `/usr/local/bin`):
   ```bash
   sudo cp do-rec.sh /usr/local/bin/do-rec
   sudo chmod +x /usr/local/bin/do-rec
   ```

3. Create a configuration file named `do-rec.ini` in your home directory:
   ```bash
   touch ~/do-rec.ini
   ```

---

## Configuration

### Default Parameters
If the `do-rec.ini` file is not present, the script uses the following defaults:
- **Total Duration**: 48 hours
- **File Duration**: 30 minutes
- **Sample Rate**: 48,000 Hz
- **Output Directory**: `~/Rec/WAV/`
- **Email for Notifications**: `evaldojr@evaldo.com`

### Example `do-rec.ini`
Here’s an example configuration file:
```ini
# Recording Configuration
TOTAL_DURATION_SECONDS=3600   # 1 hour
FILE_DURATION_SECONDS=900     # 15 minutes
RATE=44100                    # 44.1 kHz sample rate

# Paths
WAVPATH=~/Recordings/WAV/
LOGPATH=~/Recordings/log/
NAS=/mnt/nas/RAW_SOUND/

# Email Configuration
LOG_EMAIL=your-email@example.com
```

---

## Usage

### Basic Commands
Run the script with optional flags to customize the recording session:
```bash
do-rec [options]
```

### Options
| Option       | Description                                                              |
|--------------|--------------------------------------------------------------------------|
| `-d <hours>` | Total recording duration (default: 48 hours).                            |
| `-f <minutes>` | File split duration (default: 30 minutes).                              |
| `-i <hh:mm>` | Schedule recording to start at a specific time.                          |
| `-l`         | Save recordings locally (default: `~/Rec/WAV/`).                         |
| `-n`         | Save recordings on a network location (e.g., NAS).                       |
| `-o <path>`  | Specify a custom save path for recordings.                               |
| `-s <rate>`  | Set the audio sample rate (e.g., 8000, 16000, 32000, 48000 Hz).          |
| `-b`         | Enable debug mode for detailed output.                                   |
| `-h`         | Display help information.                                               |

### Examples
- Record for 24 hours, split into 15-minute files, and save locally:
  ```bash
  do-rec -d 24 -f 15 -l
  ```
- Start recording at 10:00 PM and save files to an external hard drive:
  ```bash
  do-rec -i 22:00 -o /mnt/external_drive/Recordings
  ```

---

## Logging and Notifications

- **Log Files**: Detailed logs are stored in the directory specified by `LOGPATH` (default: `~/Rec/log/`).
- **Email Alerts**: Configure the email utility and recipient in `do-rec.ini` to receive notifications about session progress and errors.

---

## Troubleshooting

- **Missing Email Utility**: Ensure one of the supported email utilities (`mutt`, `mail`, `sendmail`, `msmtp`) is installed and configured on your system.
- **Permission Issues**: Ensure the script and output directories have the correct permissions:
  ```bash
  chmod +x /usr/local/bin/do-rec
  chmod -R 755 ~/Rec
  ```
- **`arecord` Not Found**: Install ALSA utilities:
  ```bash
  sudo apt install alsa-utils
  ```

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## Contributing

Contributions are welcome! Please submit a pull request or open an issue for suggestions, bugs, or improvements.

---

