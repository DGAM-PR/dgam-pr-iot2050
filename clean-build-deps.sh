#!/bin/bash
#
# Clean Build Dependencies and Artifacts
# Removes build artifacts and fetched repositories to start fresh
#
# Usage: ./clean-build-deps.sh [--force]
#

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directories to remove
DIRS_TO_REMOVE=(
    "build"
    "isar"
    "meta-iot2050"
    "cip-core"
)

# Check if --force flag is provided
FORCE=0
if [ "$1" == "--force" ] || [ "$1" == "-f" ]; then
    FORCE=1
fi

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to get directory size
get_dir_size() {
    if [ -d "$1" ]; then
        du -sh "$1" 2>/dev/null | cut -f1
    else
        echo "N/A"
    fi
}

# Check what exists
print_info "Checking for build artifacts and dependencies..."
echo ""

FOUND_DIRS=()
TOTAL_SIZE=0

for dir in "${DIRS_TO_REMOVE[@]}"; do
    if [ -d "$dir" ]; then
        SIZE=$(get_dir_size "$dir")
        echo "  ✓ Found: $dir ($SIZE)"
        FOUND_DIRS+=("$dir")
    else
        echo "  ✗ Not found: $dir"
    fi
done

echo ""

if [ ${#FOUND_DIRS[@]} -eq 0 ]; then
    print_info "No directories to clean. Everything is already clean!"
    exit 0
fi

# Confirm deletion unless --force is used
if [ $FORCE -eq 0 ]; then
    print_warning "This will DELETE the following directories:"
    for dir in "${FOUND_DIRS[@]}"; do
        echo "  - $dir ($(get_dir_size "$dir"))"
    done
    echo ""
    print_warning "These directories will be re-downloaded/recreated on next build."
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_info "Cleanup cancelled."
        exit 0
    fi
fi

# Remove directories
print_info "Cleaning build artifacts and dependencies..."
print_info "Using sudo to remove directories (may require password)..."
echo ""

for dir in "${FOUND_DIRS[@]}"; do
    print_info "Removing: $dir"
    sudo rm -rf "$dir"
    if [ $? -eq 0 ]; then
        echo "  ✓ Deleted: $dir"
    else
        print_error "Failed to delete: $dir"
    fi
done

echo ""
print_info "Cleanup complete!"
print_info "Run './kas-container --isar build kas/dgam-pr.yml' to rebuild from scratch."
