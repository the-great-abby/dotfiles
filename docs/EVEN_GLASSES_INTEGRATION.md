# Even Glasses Integration Guide

This guide explains how to integrate Even AI glasses with your GTD system for receiving notifications directly on your glasses.

## Overview

The Even glasses integration allows you to receive GTD notifications (task completions, inbox reminders, deadlines, etc.) displayed on your Even AI glasses via Bluetooth Low Energy (BLE).

## Features

- **Dual BLE Communication**: Connects to both left and right arms of the glasses
- **Automatic Text Wrapping**: Breaks long text into multiple screens
- **Automatic/Manual Mode**: Auto-advance through screens or manual control
- **Seamless Integration**: Works alongside existing notification methods (macOS notifications, Discord, etc.)

## Prerequisites

1. **Even AI Glasses** (G1 model)
2. **Python 3.8+** with `bleak` library installed
3. **macOS** (tested on macOS; Linux should work but may require different BLE setup)
4. **Bluetooth enabled** on your computer

## Installation

### 1. Install Python Dependencies

Install the `bleak` library for BLE communication:

```bash
# Using pip (system-wide)
pip3 install bleak

# Or using the MCP virtual environment
cd ~/code/dotfiles/mcp
source venv/bin/activate
pip install bleak
```

If you're using the MCP virtual environment, the dependency is already in `requirements.txt`:

```bash
cd ~/code/dotfiles/mcp
source venv/bin/activate
pip install -r requirements.txt
```

### 2. Verify Installation

Test that the script works:

```bash
python3 ~/code/dotfiles/bin/gtd_even_glasses.py --help
```

## Configuration

Add the following to your `.gtd_config` file (located at `~/code/dotfiles/zsh/.gtd_config` or `~/.gtd_config`):

```bash
# Enable Even glasses notifications
GTD_EVEN_GLASSES_ENABLED="true"

# Optional: Use Even glasses as primary notification method
# GTD_NOTIFICATION_METHOD="even_glasses"

# Or use Even glasses in addition to other methods (recommended)
GTD_NOTIFICATION_METHOD="osascript"  # Keep macOS notifications
GTD_EVEN_GLASSES_ENABLED="true"       # Also send to glasses

# Optional: Configure device names if they differ from defaults
# EVEN_GLASSES_LEFT_NAME="Even-G1-L"
# EVEN_GLASSES_RIGHT_NAME="Even-G1-R"
```

### Configuration Options

- `GTD_EVEN_GLASSES_ENABLED`: Enable/disable Even glasses notifications (`true`/`false`)
- `GTD_NOTIFICATION_METHOD`: Primary notification method (`osascript`, `terminal`, `discord`, or `even_glasses`)
- `EVEN_GLASSES_LEFT_NAME`: Custom name for left arm device (default: `Even-G1-L`)
- `EVEN_GLASSES_RIGHT_NAME`: Custom name for right arm device (default: `Even-G1-R`)

## Usage

### Send Notifications via GTD System

Once configured, all GTD notifications will automatically be sent to your glasses:

```bash
# Task completion notification
gtd-task complete "Finish project proposal"
# → Sends to glasses: "Task Complete" / "Finish project proposal"

# Inbox reminder
gtd-notify inbox 5
# → Sends to glasses: "GTD Inbox" / "You have 5 item(s) in your inbox"

# Custom notification
gtd-notify "Reminder" "Don't forget your weekly review" "Stay organized"
# → Sends to glasses: "Reminder" / "Don't forget your weekly review" / "Stay organized"

# Deadline warning
gtd-notify deadline "Submit report" "2 hours"
# → Sends to glasses: "Deadline Approaching" / "Submit report" / "Due in 2 hours"
```

### Direct Script Usage

You can also use the script directly:

```bash
# Scan for devices
python3 ~/code/dotfiles/bin/gtd_even_glasses.py --scan

# Send simple text
python3 ~/code/dotfiles/bin/gtd_even_glasses.py "Hello from GTD system!"

# Send formatted notification
python3 ~/code/dotfiles/bin/gtd_even_glasses.py \
  --title "Task Complete" \
  --message "Finish project proposal" \
  --subtitle "Great job!"

# Use manual mode (user controls screen advancement)
python3 ~/code/dotfiles/bin/gtd_even_glasses.py --manual "Long text here..."
```

### Test Connection

Before using in production, test the connection:

```bash
# Scan for devices
python3 ~/code/dotfiles/bin/gtd_even_glasses.py --scan

# Send a test notification
python3 ~/code/dotfiles/bin/gtd_even_glasses.py \
  --title "Test" \
  --message "This is a test notification from your GTD system"
```

## How It Works

### Protocol Implementation

The integration implements the Even glasses BLE protocol:

1. **Device Discovery**: Scans for left and right BLE devices
2. **Connection**: Establishes BLE connections to both arms
3. **Text Formatting**: Splits text into screens based on display constraints (488 pixels width, ~5 lines per screen)
4. **Packet Creation**: Creates BLE packets according to protocol (Command 0x4E for text sending)
5. **Dual Transmission**: Sends to left arm first, then right arm (as per protocol requirements)
6. **Screen Advancement**: Automatically advances through screens or waits for user input in manual mode

### Text Display

Text is formatted as:
```
Title
Subtitle (if provided)
Message
```

Long text is automatically:
- Word-wrapped to fit screen width (~40 characters per line)
- Split into multiple screens (~5 lines per screen)
- Displayed sequentially with automatic advancement

## Troubleshooting

### Device Not Found

If the script can't find your glasses:

1. **Check Bluetooth**: Ensure Bluetooth is enabled and glasses are powered on
2. **Check Device Names**: Your glasses might use different names. Run scan to see:
   ```bash
   python3 ~/code/dotfiles/bin/gtd_even_glasses.py --scan
   ```
3. **Update Config**: If names differ, update `EVEN_GLASSES_LEFT_NAME` and `EVEN_GLASSES_RIGHT_NAME` in `.gtd_config`

### Connection Failures

If connection fails:

1. **Check Permissions**: macOS may require Bluetooth permissions. Check System Preferences → Security & Privacy → Privacy → Bluetooth
2. **Check Distance**: Ensure glasses are within BLE range (~10 meters)
3. **Check Pairing**: Glasses may need to be paired with your Mac first (via System Preferences → Bluetooth)
4. **Check Other Apps**: Close other apps that might be using the glasses

### Characteristic Not Found

If you see "Could not find writeable characteristic":

1. **Service UUIDs**: The default service/characteristic UUIDs might not match your device. You may need to:
   - Check the EvenDemoApp source code for correct UUIDs
   - Use a BLE scanner app to find the correct UUIDs
   - Update the `EvenGlassesConfig` in the Python script

### Text Not Displaying

If text is sent but not displaying:

1. **Check Formatting**: Very long text might need manual mode for better control
2. **Check Mode**: Ensure automatic mode is appropriate for your use case
3. **Check Glasses**: Verify glasses are in correct mode (not in sleep or other mode)
4. **Check Protocol**: Protocol implementation may need adjustment based on your glasses firmware version

## Advanced Configuration

### Custom Display Settings

You can customize display settings by modifying the `EvenGlassesConfig` in the Python script:

```python
config = EvenGlassesConfig(
    screen_width_pixels=488,  # Display width in pixels
    lines_per_screen=5,        # Lines per screen
    chars_per_line=40,         # Characters per line
    font_size=21,              # Font size
    screen_delay_seconds=3.0   # Delay between screens (automatic mode)
)
```

### Custom Service UUIDs

If your glasses use different BLE service UUIDs, update them:

```python
config = EvenGlassesConfig(
    service_uuid="your-service-uuid-here",
    characteristic_uuid="your-characteristic-uuid-here"
)
```

## Integration with GTD Features

The Even glasses integration works seamlessly with:

- ✅ **Task Completion**: Automatic notifications when tasks are completed
- ✅ **Inbox Processing**: Reminders when inbox has items
- ✅ **Review Reminders**: Notifications for daily/weekly/monthly reviews
- ✅ **Deadline Warnings**: Alerts for approaching deadlines
- ✅ **Custom Notifications**: Any notification sent via `gtd-notify`
- ✅ **Calendar Reminders**: Calendar events from `gtd-calendar-reminders`
- ✅ **Auto-Suggestions**: When AI suggestions are created
- ✅ **Deep Analysis**: When analysis results are ready

## Protocol Reference

Based on [EvenDemoApp](https://github.com/even-realities/EvenDemoApp):

### Text Sending (Command 0x4E)

```
Command: 0x4E
seq: Sequence number (0-255)
total_package_num: Total packets (1-255)
current_package_num: Current packet (0-255)
newscreen: Screen status (0x71 for text show)
new_char_pos0: Character position high byte
new_char_pos1: Character position low byte
current_page_num: Current page (0-255)
max_page_num: Max pages (1-255)
data: Text data (UTF-8 encoded)
```

### Screen Status Flags

- **Lower 4 bits**: Screen action
  - `0x01`: Display new content
- **Upper 4 bits**: Mode/status
  - `0x30`: Even AI displaying (automatic mode)
  - `0x40`: Even AI display complete (last page)
  - `0x50`: Even AI manual mode
  - `0x60`: Even AI network error
  - `0x70`: Text show

## Future Enhancements

Potential future improvements:

- [ ] Support for sending images (BMP format)
- [ ] Mic activation and audio data reception
- [ ] TouchBar event handling
- [ ] Even AI mode integration
- [ ] Configuration via wizard menu
- [ ] Connection pooling for faster subsequent notifications
- [ ] Offline queue for notifications when glasses are disconnected

## Support

For issues or questions:

1. Check the troubleshooting section above
2. Review the [EvenDemoApp repository](https://github.com/even-realities/EvenDemoApp) for protocol details
3. Enable verbose logging: `python3 gtd_even_glasses.py --verbose`

## License

This integration is part of the GTD system and follows the same license as the main codebase.
