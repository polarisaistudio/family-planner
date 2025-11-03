#!/bin/bash

# Test Runner Script for Family Planner
# This script runs all tests with proper configuration and reporting

set -e  # Exit on error

echo "🧪 Family Planner Test Runner"
echo "=============================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}➜${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

print_success "Flutter found: $(flutter --version | head -1)"
echo ""

# Parse command line arguments
RUN_COVERAGE=false
RUN_E2E=false
RUN_ALL=true
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --coverage)
            RUN_COVERAGE=true
            shift
            ;;
        --e2e)
            RUN_E2E=true
            RUN_ALL=false
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            echo "Usage: ./run_tests.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --coverage    Generate coverage report"
            echo "  --e2e         Run only E2E integration tests"
            echo "  --verbose     Run tests with verbose output"
            echo "  --help        Show this help message"
            echo ""
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help to see available options"
            exit 1
            ;;
    esac
done

# Get dependencies
print_status "Getting dependencies..."
flutter pub get
print_success "Dependencies installed"
echo ""

# Run tests based on options
if [ "$RUN_E2E" = true ]; then
    print_status "Running E2E integration tests..."
    echo ""

    if [ "$VERBOSE" = true ]; then
        flutter test test/integration/firebase_e2e_test.dart --verbose
    else
        flutter test test/integration/firebase_e2e_test.dart
    fi

    TEST_EXIT_CODE=$?

elif [ "$RUN_ALL" = true ]; then
    print_status "Running all tests..."
    echo ""

    if [ "$VERBOSE" = true ]; then
        if [ "$RUN_COVERAGE" = true ]; then
            flutter test --coverage --verbose
        else
            flutter test --verbose
        fi
    else
        if [ "$RUN_COVERAGE" = true ]; then
            flutter test --coverage
        else
            flutter test
        fi
    fi

    TEST_EXIT_CODE=$?
fi

echo ""

# Check test results
if [ $TEST_EXIT_CODE -eq 0 ]; then
    print_success "All tests passed!"
else
    print_error "Some tests failed"
    exit $TEST_EXIT_CODE
fi

# Generate coverage report if requested
if [ "$RUN_COVERAGE" = true ]; then
    echo ""
    print_status "Generating coverage report..."

    if command -v lcov &> /dev/null; then
        # Remove Flutter and Dart internals from coverage
        lcov --remove coverage/lcov.info \
            'lib/*/*.g.dart' \
            'lib/generated_plugin_registrant.dart' \
            'lib/firebase_options*.dart' \
            -o coverage/lcov.info

        if command -v genhtml &> /dev/null; then
            genhtml coverage/lcov.info -o coverage/html
            print_success "Coverage report generated: coverage/html/index.html"

            # Try to open coverage report
            if [[ "$OSTYPE" == "darwin"* ]]; then
                open coverage/html/index.html
            elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
                xdg-open coverage/html/index.html 2>/dev/null || true
            fi
        else
            print_warning "genhtml not found. Install lcov to generate HTML reports"
            print_warning "  macOS: brew install lcov"
            print_warning "  Linux: sudo apt-get install lcov"
        fi
    else
        print_warning "lcov not found. Install lcov for detailed coverage reports"
        print_warning "  macOS: brew install lcov"
        print_warning "  Linux: sudo apt-get install lcov"
        print_warning "Raw coverage data: coverage/lcov.info"
    fi
fi

echo ""
print_success "Test run complete!"
