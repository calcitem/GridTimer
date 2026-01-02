#!/bin/bash

# ADB wireless debugging connection script
# This script enables wireless debugging and connects to the device over WiFi

set -e

PORT=5555

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== ADB Wireless Debugging Setup ==="

# Check if adb is available
if ! command -v adb &> /dev/null; then
    echo -e "${RED}Error: adb command not found. Please install Android SDK Platform Tools.${NC}"
    exit 1
fi

# List current devices
echo ""
echo "Current connected devices:"
adb devices

# Check if any USB device is connected
USB_DEVICE=$(adb devices | grep -v "List" | grep -E "^[^\s]+" | grep -v ":" | head -n 1 | awk '{print $1}')

if [ -z "$USB_DEVICE" ]; then
    echo -e "${YELLOW}No USB device found.${NC}"
    echo ""

    # Check if already connected via WiFi
    WIFI_DEVICE=$(adb devices | grep -v "List" | grep -E ":[0-9]+" | head -n 1 | awk '{print $1}')

    if [ -n "$WIFI_DEVICE" ]; then
        echo -e "${GREEN}Already connected via WiFi: $WIFI_DEVICE${NC}"
        exit 0
    fi

    echo "Please connect your device via USB first, then run this script again."
    echo ""
    echo "Alternatively, you can manually connect if you know your device IP:"
    echo "  adb connect <IP_ADDRESS>:$PORT"
    exit 1
fi

echo ""
echo -e "USB device found: ${GREEN}$USB_DEVICE${NC}"

# Get the device IP address from wlan0 interface
echo ""
echo "Detecting device IP address..."

# Try multiple methods to get IP address
DEVICE_IP=""

# Method 1: Using ip addr show wlan0
DEVICE_IP=$(adb -s "$USB_DEVICE" shell "ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print \$2}' | cut -d/ -f1" 2>/dev/null | tr -d '\r\n')

# Method 2: If Method 1 fails, try ifconfig
if [ -z "$DEVICE_IP" ]; then
    DEVICE_IP=$(adb -s "$USB_DEVICE" shell "ifconfig wlan0 2>/dev/null | grep 'inet addr' | awk -F: '{print \$2}' | awk '{print \$1}'" 2>/dev/null | tr -d '\r\n')
fi

# Method 3: Try ip route
if [ -z "$DEVICE_IP" ]; then
    DEVICE_IP=$(adb -s "$USB_DEVICE" shell "ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K[0-9.]+'" 2>/dev/null | tr -d '\r\n')
fi

# Method 4: Check Settings (works on some devices)
if [ -z "$DEVICE_IP" ]; then
    DEVICE_IP=$(adb -s "$USB_DEVICE" shell "settings get global wifi_static_ip 2>/dev/null" 2>/dev/null | tr -d '\r\n')
    if [ "$DEVICE_IP" = "null" ]; then
        DEVICE_IP=""
    fi
fi

if [ -z "$DEVICE_IP" ]; then
    echo -e "${YELLOW}Warning: Could not auto-detect device IP address.${NC}"
    echo ""
    echo "Please find your device IP manually:"
    echo "  Settings > About phone > Status > IP address"
    echo "  or"
    echo "  Settings > Wi-Fi > [Connected network] > Details"
    echo ""
    read -p "Enter device IP address: " DEVICE_IP

    if [ -z "$DEVICE_IP" ]; then
        echo -e "${RED}Error: No IP address provided.${NC}"
        exit 1
    fi
fi

echo -e "Device IP: ${GREEN}$DEVICE_IP${NC}"

# Enable TCP/IP mode on the device
echo ""
echo "Enabling TCP/IP mode on port $PORT..."
adb -s "$USB_DEVICE" tcpip $PORT

# Wait for the device to restart adbd
echo "Waiting for device to restart adb daemon..."
sleep 2

# Connect to the device over WiFi
echo ""
echo "Connecting to $DEVICE_IP:$PORT..."
CONNECT_RESULT=$(adb connect "$DEVICE_IP:$PORT" 2>&1)
echo "$CONNECT_RESULT"

# Verify connection
sleep 1
echo ""
echo "Verifying connection..."
adb devices

# Check if connection was successful
if echo "$CONNECT_RESULT" | grep -q "connected"; then
    echo ""
    echo -e "${GREEN}=== Wireless debugging connected successfully! ===${NC}"
    echo ""
    echo "You can now disconnect the USB cable."
    echo "To disconnect wireless debugging, run: adb disconnect $DEVICE_IP:$PORT"
else
    echo ""
    echo -e "${YELLOW}Connection may have failed. Please check:${NC}"
    echo "  1. Device and computer are on the same WiFi network"
    echo "  2. Firewall is not blocking port $PORT"
    echo "  3. Try running: adb connect $DEVICE_IP:$PORT"
fi
