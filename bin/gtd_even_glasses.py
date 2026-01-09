#!/usr/bin/env python3
"""
GTD Even Glasses Integration
Communicates with Even AI glasses via Bluetooth Low Energy (BLE)

Based on EvenDemoApp protocol:
https://github.com/even-realities/EvenDemoApp

Protocol details:
- Command 0x4E: Send text to glasses
- Command 0x0E: Open/close glasses microphone
- Command 0xF1: Receive mic data
- Command 0xF5: TouchBar events and Even AI commands
"""

import asyncio
import sys
import logging
import os
from pathlib import Path
from typing import Optional, List, Tuple, Dict
from dataclasses import dataclass, field
from enum import IntEnum

try:
    from bleak import BleakClient, BleakScanner
    from bleak.backends.device import BLEDevice
except ImportError:
    print("❌ Error: bleak library not installed")
    print("   Install with: pip install bleak")
    sys.exit(1)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class ScreenStatus(IntEnum):
    """Screen status flags for Even glasses protocol"""
    # Lower 4 bits (Screen Action)
    DISPLAY_NEW_CONTENT = 0x01
    
    # Upper 4 bits (Even AI Status / Text Show)
    EVEN_AI_DISPLAYING = 0x30  # Automatic mode default
    EVEN_AI_DISPLAY_COMPLETE = 0x40  # Last page of automatic mode
    EVEN_AI_MANUAL_MODE = 0x50
    EVEN_AI_NETWORK_ERROR = 0x60
    TEXT_SHOW = 0x70
    
    # Combined (most common)
    NEW_CONTENT_TEXT_SHOW = 0x71
    NEW_CONTENT_EVEN_AI_DISPLAYING = 0x31


def load_config_from_file() -> Dict[str, str]:
    """Load configuration from .gtd_config file"""
    config = {}
    config_paths = [
        Path.home() / "code" / "dotfiles" / "zsh" / ".gtd_config",
        Path.home() / "code" / "personal" / "dotfiles" / "zsh" / ".gtd_config",
        Path.home() / ".gtd_config",
    ]
    
    for config_path in config_paths:
        if config_path.exists():
            try:
                with open(config_path, "r") as f:
                    for line in f:
                        line = line.strip()
                        # Skip comments and empty lines
                        if not line or line.startswith("#"):
                            continue
                        # Parse KEY="value" or KEY=value
                        if "=" in line:
                            key, value = line.split("=", 1)
                            key = key.strip()
                            value = value.strip()
                            # Remove quotes if present
                            if value.startswith('"') and value.endswith('"'):
                                value = value[1:-1]
                            elif value.startswith("'") and value.endswith("'"):
                                value = value[1:-1]
                            # Handle ${VAR:-default} syntax
                            if value.startswith("${") and ":-" in value:
                                var_name = value[2:value.index(":-")]
                                default = value[value.index(":-") + 2:-1]
                                value = os.environ.get(var_name, default)
                            config[key] = value
                break
            except Exception as e:
                logger.debug(f"Error reading config from {config_path}: {e}")
    
    return config


@dataclass
class EvenGlassesConfig:
    """Configuration for Even glasses connection"""
    # Device names or addresses to search for
    left_device_name: str = field(default="Even-G1-L")  # Common name for left arm
    right_device_name: str = field(default="Even-G1-R")  # Common name for right arm
    
    # Service UUIDs (typical BLE service/characteristic UUIDs - may need adjustment)
    service_uuid: str = field(default="0000fff0-0000-1000-8000-00805f9b34fb")  # Common BLE service
    characteristic_uuid: str = field(default="0000fff1-0000-1000-8000-00805f9b34fb")  # Common BLE characteristic
    
    # Display settings
    screen_width_pixels: int = field(default=488)
    lines_per_screen: int = field(default=5)
    chars_per_line: int = field(default=40)  # Approximate, depends on font size
    font_size: int = field(default=21)
    
    # Timing settings
    screen_delay_seconds: float = field(default=3.0)  # Delay between screens in automatic mode
    connection_timeout: float = field(default=10.0)
    scan_timeout: float = field(default=5.0)
    
    @classmethod
    def from_env(cls) -> "EvenGlassesConfig":
        """Create config from environment variables and config file"""
        # Load config file
        file_config = load_config_from_file()
        
        # Get values from environment (takes precedence) or config file or defaults
        left_name = os.environ.get(
            "EVEN_GLASSES_LEFT_NAME",
            file_config.get("EVEN_GLASSES_LEFT_NAME", "Even-G1-L")
        )
        right_name = os.environ.get(
            "EVEN_GLASSES_RIGHT_NAME",
            file_config.get("EVEN_GLASSES_RIGHT_NAME", "Even-G1-R")
        )
        
        return cls(
            left_device_name=left_name,
            right_device_name=right_name,
        )


class EvenGlassesConnection:
    """Manages BLE connection to Even glasses"""
    
    def __init__(self, config: Optional[EvenGlassesConfig] = None):
        self.config = config or EvenGlassesConfig()
        self.left_client: Optional[BleakClient] = None
        self.right_client: Optional[BleakClient] = None
        self.left_device: Optional[BLEDevice] = None
        self.right_device: Optional[BLEDevice] = None
        self.sequence_number = 0
    
    async def scan_for_devices(self) -> Tuple[Optional[BLEDevice], Optional[BLEDevice]]:
        """Scan for Even glasses devices"""
        logger.info(f"Scanning for Even glasses devices (timeout: {self.config.scan_timeout}s)...")
        
        devices = await BleakScanner.discover(timeout=self.config.scan_timeout)
        
        left_device = None
        right_device = None
        
        for device in devices:
            name = device.name or ""
            address = device.address
            
            logger.debug(f"Found device: {name} ({address})")
            
            # Check if this matches our expected device names
            if self.config.left_device_name.lower() in name.lower():
                left_device = device
                logger.info(f"✓ Found left device: {name} ({address})")
            elif self.config.right_device_name.lower() in name.lower():
                right_device = device
                logger.info(f"✓ Found right device: {name} ({address})")
        
        if not left_device:
            logger.warning(f"⚠️  Left device '{self.config.left_device_name}' not found")
        if not right_device:
            logger.warning(f"⚠️  Right device '{self.config.right_device_name}' not found")
        
        return left_device, right_device
    
    async def connect(self, left_device: Optional[BLEDevice] = None, 
                     right_device: Optional[BLEDevice] = None) -> bool:
        """Connect to Even glasses devices"""
        if not left_device or not right_device:
            left_device, right_device = await self.scan_for_devices()
        
        if not left_device or not right_device:
            logger.error("❌ Could not find both left and right devices")
            return False
        
        self.left_device = left_device
        self.right_device = right_device
        
        try:
            # Connect to left device
            logger.info(f"Connecting to left device: {left_device.address}")
            self.left_client = BleakClient(left_device, timeout=self.config.connection_timeout)
            await self.left_client.connect()
            logger.info("✓ Connected to left device")
            
            # Connect to right device
            logger.info(f"Connecting to right device: {right_device.address}")
            self.right_client = BleakClient(right_device, timeout=self.config.connection_timeout)
            await self.right_client.connect()
            logger.info("✓ Connected to right device")
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Connection failed: {e}")
            await self.disconnect()
            return False
    
    async def disconnect(self):
        """Disconnect from both devices"""
        if self.left_client and self.left_client.is_connected:
            try:
                await self.left_client.disconnect()
                logger.info("✓ Disconnected from left device")
            except Exception as e:
                logger.warning(f"Error disconnecting left: {e}")
        
        if self.right_client and self.right_client.is_connected:
            try:
                await self.right_client.disconnect()
                logger.info("✓ Disconnected from right device")
            except Exception as e:
                logger.warning(f"Error disconnecting right: {e}")
        
        self.left_client = None
        self.right_client = None
    
    def _get_next_sequence(self) -> int:
        """Get next sequence number (0-255, wraps around)"""
        seq = self.sequence_number
        self.sequence_number = (self.sequence_number + 1) % 256
        return seq
    
    def _split_text_into_screens(self, text: str) -> List[str]:
        """Split text into screens based on display constraints"""
        # Simple splitting by lines - could be enhanced with proper word wrapping
        lines = text.split('\n')
        
        screens = []
        current_screen_lines = []
        
        for line in lines:
            # If line is too long, wrap it
            if len(line) > self.config.chars_per_line:
                # Simple word wrap (split at spaces)
                words = line.split(' ')
                current_line = ""
                
                for word in words:
                    if len(current_line) + len(word) + 1 <= self.config.chars_per_line:
                        current_line += (" " if current_line else "") + word
                    else:
                        if current_line:
                            current_screen_lines.append(current_line)
                        if len(current_screen_lines) >= self.config.lines_per_screen:
                            screens.append('\n'.join(current_screen_lines))
                            current_screen_lines = []
                        current_line = word
                
                if current_line:
                    current_screen_lines.append(current_line)
            else:
                current_screen_lines.append(line)
            
            # Check if we've filled a screen
            if len(current_screen_lines) >= self.config.lines_per_screen:
                screens.append('\n'.join(current_screen_lines))
                current_screen_lines = []
        
        # Add remaining lines as last screen
        if current_screen_lines:
            screens.append('\n'.join(current_screen_lines))
        
        return screens if screens else [""]
    
    def _create_text_packet(self, data: bytes, seq: int, total_packets: int, 
                           current_packet: int, screen_status: int, 
                           char_position: int, current_page: int, 
                           max_pages: int) -> bytes:
        """Create a text packet according to Even glasses protocol"""
        # Protocol: Command 0x4E
        # seq (1 byte), total_package_num (1 byte), current_package_num (1 byte),
        # newscreen (1 byte), new_char_pos0 (1 byte), new_char_pos1 (1 byte),
        # current_page_num (1 byte), max_page_num (1 byte), data (variable)
        
        packet = bytearray()
        packet.append(0x4E)  # Command: Send text
        packet.append(seq & 0xFF)  # Sequence number
        packet.append(total_packets & 0xFF)  # Total packets
        packet.append(current_packet & 0xFF)  # Current packet
        packet.append(screen_status & 0xFF)  # Screen status
        packet.append((char_position >> 8) & 0xFF)  # Char position high byte
        packet.append(char_position & 0xFF)  # Char position low byte
        packet.append(current_page & 0xFF)  # Current page
        packet.append(max_pages & 0xFF)  # Max pages
        packet.extend(data)  # Data
        
        return bytes(packet)
    
    async def _send_to_device(self, client: BleakClient, data: bytes, 
                             device_name: str) -> bool:
        """Send data to a specific device"""
        if not client or not client.is_connected:
            logger.error(f"❌ {device_name} not connected")
            return False
        
        try:
            # Find the characteristic (this may need adjustment based on actual device)
            services = await client.get_services()
            
            # Try to find the characteristic
            characteristic = None
            for service in services:
                for char in service.characteristics:
                    if "write" in char.properties:
                        characteristic = char
                        break
                if characteristic:
                    break
            
            if not characteristic:
                # Try using the configured UUID
                try:
                    service = services.get_service(self.config.service_uuid)
                    if service:
                        characteristic = service.get_characteristic(self.config.characteristic_uuid)
                except Exception:
                    pass
            
            if not characteristic:
                logger.error(f"❌ Could not find writeable characteristic on {device_name}")
                return False
            
            await client.write_gatt_char(characteristic, data)
            logger.debug(f"✓ Sent {len(data)} bytes to {device_name}")
            return True
            
        except Exception as e:
            logger.error(f"❌ Error sending to {device_name}: {e}")
            return False
    
    async def send_text(self, text: str, automatic_mode: bool = True) -> bool:
        """
        Send text to glasses
        
        Args:
            text: Text to display
            automatic_mode: If True, auto-advance screens; if False, manual mode
        
        Returns:
            True if successful, False otherwise
        """
        if not self.left_client or not self.right_client:
            logger.error("❌ Not connected to glasses")
            return False
        
        # Split text into screens
        screens = self._split_text_into_screens(text)
        max_pages = len(screens)
        
        logger.info(f"Sending {max_pages} screen(s) to glasses...")
        
        char_position = 0
        
        for page_num, screen_text in enumerate(screens):
            # Determine screen status based on mode and page
            if automatic_mode:
                if page_num == max_pages - 1:
                    # Last page
                    screen_status = ScreenStatus.DISPLAY_NEW_CONTENT | ScreenStatus.EVEN_AI_DISPLAY_COMPLETE
                else:
                    # Middle pages
                    screen_status = ScreenStatus.DISPLAY_NEW_CONTENT | ScreenStatus.EVEN_AI_DISPLAYING
            else:
                # Manual mode
                screen_status = ScreenStatus.DISPLAY_NEW_CONTENT | ScreenStatus.EVEN_AI_MANUAL_MODE
            
            # Convert screen text to bytes (UTF-8)
            screen_bytes = screen_text.encode('utf-8')
            
            # Split into packets if needed (BLE MTU is typically 20-23 bytes)
            # For simplicity, we'll send as one packet per screen (may need adjustment)
            # If screen is too large, split into multiple packets
            max_packet_size = 100  # Conservative limit
            packets = []
            
            if len(screen_bytes) <= max_packet_size:
                packets = [screen_bytes]
            else:
                # Split into multiple packets
                for i in range(0, len(screen_bytes), max_packet_size):
                    packets.append(screen_bytes[i:i + max_packet_size])
            
            total_packets = len(packets)
            
            # Send packets to left device first
            for packet_num, packet_data in enumerate(packets):
                seq = self._get_next_sequence()
                packet = self._create_text_packet(
                    packet_data, seq, total_packets, packet_num,
                    screen_status if packet_num == 0 else 0,  # Only set status on first packet
                    char_position, page_num, max_pages
                )
                
                success = await self._send_to_device(self.left_client, packet, "left")
                if not success:
                    logger.error("❌ Failed to send to left device")
                    return False
                
                # Wait for acknowledgment (protocol requires this)
                await asyncio.sleep(0.1)  # Small delay between packets
                char_position += len(packet_data)
            
            # After left side succeeds, send to right side
            char_position = 0  # Reset for right side
            for packet_num, packet_data in enumerate(packets):
                seq = self._get_next_sequence()
                packet = self._create_text_packet(
                    packet_data, seq, total_packets, packet_num,
                    screen_status if packet_num == 0 else 0,
                    char_position, page_num, max_pages
                )
                
                success = await self._send_to_device(self.right_client, packet, "right")
                if not success:
                    logger.error("❌ Failed to send to right device")
                    return False
                
                await asyncio.sleep(0.1)
                char_position += len(packet_data)
            
            # Delay between screens in automatic mode
            if automatic_mode and page_num < max_pages - 1:
                await asyncio.sleep(self.config.screen_delay_seconds)
        
        logger.info("✓ Text sent successfully")
        return True


async def send_notification_to_glasses(title: str, message: str, 
                                      subtitle: Optional[str] = None,
                                      config: Optional[EvenGlassesConfig] = None) -> bool:
    """
    Send a notification to Even glasses
    
    Args:
        title: Notification title
        message: Notification message
        subtitle: Optional subtitle
        config: Optional configuration
    
    Returns:
        True if successful, False otherwise
    """
    # Format the notification text
    text_parts = [title]
    if subtitle:
        text_parts.append(subtitle)
    if message:
        text_parts.append(message)
    text = '\n'.join(text_parts)
    
    # Connect and send
    connection = EvenGlassesConnection(config)
    
    try:
        success = await connection.connect()
        if not success:
            return False
        
        return await connection.send_text(text, automatic_mode=True)
        
    except Exception as e:
        logger.error(f"❌ Error sending notification: {e}")
        return False
    finally:
        await connection.disconnect()


def main():
    """CLI interface for testing"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Send text to Even glasses")
    parser.add_argument("text", nargs="?", help="Text to send")
    parser.add_argument("--title", help="Notification title")
    parser.add_argument("--message", help="Notification message")
    parser.add_argument("--subtitle", help="Notification subtitle")
    parser.add_argument("--scan", action="store_true", help="Scan for devices only")
    parser.add_argument("--manual", action="store_true", help="Use manual mode")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose logging")
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    async def run():
        # Load config from environment/config file
        config = EvenGlassesConfig.from_env()
        
        if args.scan:
            connection = EvenGlassesConnection(config)
            left, right = await connection.scan_for_devices()
            if left:
                print(f"✓ Left: {left.name} ({left.address})")
            else:
                print("❌ Left device not found")
                print(f"   Expected name: {config.left_device_name}")
            if right:
                print(f"✓ Right: {right.name} ({right.address})")
            else:
                print("❌ Right device not found")
                print(f"   Expected name: {config.right_device_name}")
            return
        
        # If title/message are provided, use notification function
        if args.title or args.message:
            success = await send_notification_to_glasses(
                args.title or "Notification",
                args.message or "",
                args.subtitle,
                config
            )
            if success:
                print("✓ Notification sent successfully")
            else:
                print("❌ Failed to send notification")
                sys.exit(1)
            return
        
        # Otherwise, send text directly
        text = args.text
        if not text:
            parser.print_help()
            sys.exit(1)
        
        connection = EvenGlassesConnection(config)
        success = await connection.connect()
        if not success:
            print("❌ Failed to connect to glasses")
            sys.exit(1)
        
        try:
            await connection.send_text(text, automatic_mode=not args.manual)
            print("✓ Text sent successfully")
        except Exception as e:
            print(f"❌ Error: {e}")
            sys.exit(1)
        finally:
            await connection.disconnect()
    
    asyncio.run(run())


if __name__ == "__main__":
    main()
