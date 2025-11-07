#!/bin/bash

echo "🔄 Stopping existing Notch app..."
killall Notch 2>/dev/null
sleep 1

echo "🚀 Starting Notch app..."
open "/Users/nikitastogniy/Library/Developer/Xcode/DerivedData/Notch-dtqnsbegdhtmoscnozxlmgmvjnqf/Build/Products/Debug/Notch.app"

sleep 2

echo "📋 Streaming logs... (press Ctrl+C to stop)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Stream all Notch process output
log stream --process Notch --level debug --style compact 2>&1
