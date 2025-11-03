#!/bin/bash

# Family Planner Setup Verification Script
# This script checks if your setup is ready to run

echo "🔍 Family Planner Setup Verification"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counter for issues
ISSUES=0

# Check 1: Flutter installation
echo "1️⃣  Checking Flutter installation..."
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    echo -e "${GREEN}✅ Flutter found: $FLUTTER_VERSION${NC}"
else
    echo -e "${RED}❌ Flutter not found. Please install Flutter first.${NC}"
    ISSUES=$((ISSUES + 1))
fi
echo ""

# Check 2: Dependencies installed
echo "2️⃣  Checking if dependencies are installed..."
if [ -d "pubspec.lock" ] || [ -f "pubspec.lock" ]; then
    echo -e "${GREEN}✅ Dependencies installed (pubspec.lock found)${NC}"
else
    echo -e "${YELLOW}⚠️  Dependencies not installed. Run: flutter pub get${NC}"
    ISSUES=$((ISSUES + 1))
fi
echo ""

# Check 3: Supabase configuration
echo "3️⃣  Checking Supabase configuration..."
CONFIG_FILE="lib/core/constants/supabase_config.dart"

if [ -f "$CONFIG_FILE" ]; then
    echo -e "${GREEN}✅ Config file found${NC}"

    # Check if URL is configured
    if grep -q "YOUR_SUPABASE_URL_HERE" "$CONFIG_FILE"; then
        echo -e "${RED}❌ Supabase URL not configured (still using placeholder)${NC}"
        echo "   👉 Update: $CONFIG_FILE"
        ISSUES=$((ISSUES + 1))
    else
        echo -e "${GREEN}✅ Supabase URL configured${NC}"
    fi

    # Check if anon key is configured
    if grep -q "YOUR_SUPABASE_ANON_KEY_HERE" "$CONFIG_FILE"; then
        echo -e "${RED}❌ Supabase anon key not configured (still using placeholder)${NC}"
        echo "   👉 Update: $CONFIG_FILE"
        ISSUES=$((ISSUES + 1))
    else
        echo -e "${GREEN}✅ Supabase anon key configured${NC}"
    fi
else
    echo -e "${RED}❌ Config file not found: $CONFIG_FILE${NC}"
    ISSUES=$((ISSUES + 1))
fi
echo ""

# Check 4: Database schema file exists
echo "4️⃣  Checking database schema..."
if [ -f "database/schema.sql" ]; then
    echo -e "${GREEN}✅ Database schema file found${NC}"
    LINE_COUNT=$(wc -l < "database/schema.sql")
    echo "   📄 Schema file has $LINE_COUNT lines"
else
    echo -e "${RED}❌ Database schema file not found${NC}"
    ISSUES=$((ISSUES + 1))
fi
echo ""

# Check 5: Connected devices
echo "5️⃣  Checking for connected devices..."
DEVICES=$(flutter devices 2>/dev/null | grep -c "•")
if [ "$DEVICES" -gt 0 ]; then
    echo -e "${GREEN}✅ Found $DEVICES device(s)${NC}"
    flutter devices 2>/dev/null | grep "•"
else
    echo -e "${YELLOW}⚠️  No devices found. Start an emulator or connect a device.${NC}"
    echo "   💡 iOS: Open Xcode Simulator"
    echo "   💡 Android: Start Android Emulator"
fi
echo ""

# Check 6: Required files exist
echo "6️⃣  Checking required files..."
REQUIRED_FILES=(
    "lib/main.dart"
    "lib/features/auth/presentation/pages/login_page.dart"
    "lib/features/calendar/presentation/pages/calendar_page.dart"
    "pubspec.yaml"
)

for FILE in "${REQUIRED_FILES[@]}"; do
    if [ -f "$FILE" ]; then
        echo -e "${GREEN}✅ $FILE${NC}"
    else
        echo -e "${RED}❌ Missing: $FILE${NC}"
        ISSUES=$((ISSUES + 1))
    fi
done
echo ""

# Summary
echo "======================================"
echo "📊 SUMMARY"
echo "======================================"
echo ""

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}🎉 All checks passed! You're ready to run the app!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Make sure you've set up Supabase (see SETUP_GUIDE.md)"
    echo "2. Run the database schema in Supabase SQL Editor"
    echo "3. Run: flutter run"
else
    echo -e "${RED}⚠️  Found $ISSUES issue(s) that need attention${NC}"
    echo ""
    echo "Please fix the issues above before running the app."
    echo "See SETUP_GUIDE.md for detailed instructions."
fi
echo ""

# Additional reminders
echo "======================================"
echo "📝 REMINDERS"
echo "======================================"
echo ""
echo "Have you completed these steps in Supabase?"
echo ""
echo "☐ Created Supabase project"
echo "☐ Ran database/schema.sql in SQL Editor"
echo "☐ Enabled email authentication"
echo "☐ Copied Project URL and anon key"
echo "☐ Updated lib/core/constants/supabase_config.dart"
echo ""
echo "If not, follow SETUP_GUIDE.md for step-by-step instructions."
echo ""
