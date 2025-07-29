#!/bin/bash
#
# bcmstat Installation Script
# Enhanced version with Pi5 support by pplovebobo
#
# Usage: curl -sSL https://raw.githubusercontent.com/pplovebobo/bcmstat/master/install.sh | bash
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Raspberry Pi
check_raspberry_pi() {
    if [ ! -f /proc/cpuinfo ] || ! grep -q "Raspberry Pi\|BCM" /proc/cpuinfo; then
        print_warning "This tool is designed for Raspberry Pi, but will attempt to install anyway."
    else
        print_status "Raspberry Pi detected. Proceeding with installation."
    fi
}

# Check Python installation
check_python() {
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_CMD="python3"
        print_status "Python 3 found: $(python3 --version)"
    elif command -v python >/dev/null 2>&1; then
        PYTHON_CMD="python"
        print_status "Python found: $(python --version)"
    else
        print_error "Python is not installed. Please install Python and try again."
        exit 1
    fi
}

# Main installation
main() {
    print_status "Starting bcmstat installation..."
    
    check_raspberry_pi
    check_python
    
    # Download bcmstat
    print_status "Downloading bcmstat.sh..."
    if command -v curl >/dev/null 2>&1; then
        curl -Ls https://raw.githubusercontent.com/pplovebobo/bcmstat/master/bcmstat.sh -o /tmp/bcmstat.sh
    elif command -v wget >/dev/null 2>&1; then
        wget -q https://raw.githubusercontent.com/pplovebobo/bcmstat/master/bcmstat.sh -O /tmp/bcmstat.sh
    else
        print_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    
    # Make executable and move to /usr/local/bin
    chmod +x /tmp/bcmstat.sh
    
    # Try to install system-wide, fallback to local
    if [ "$(id -u)" = "0" ] || sudo -n true 2>/dev/null; then
        print_status "Installing to /usr/local/bin/bcmstat (system-wide)..."
        sudo mv /tmp/bcmstat.sh /usr/local/bin/bcmstat
        INSTALL_PATH="/usr/local/bin/bcmstat"
    else
        print_status "Installing to ~/bin/bcmstat (user-local)..."
        mkdir -p ~/bin
        mv /tmp/bcmstat.sh ~/bin/bcmstat
        INSTALL_PATH="~/bin/bcmstat"
        
        # Add to PATH if not already there
        if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
            print_status "Adding ~/bin to PATH in ~/.bashrc"
            echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
            print_warning "Please run 'source ~/.bashrc' or restart your terminal."
        fi
    fi
    
    print_status "Installation completed successfully!"
    echo ""
    print_status "Usage examples:"
    echo "  Basic monitoring:        ${PYTHON_CMD} ${INSTALL_PATH}"
    echo "  Advanced monitoring:     sudo ${PYTHON_CMD} ${INSTALL_PATH} xgpd10"
    echo "  Help:                    ${PYTHON_CMD} ${INSTALL_PATH} -h"
    echo ""
    print_status "For optimal functionality on newer Raspberry Pi models, run with sudo:"
    echo "  sudo ${PYTHON_CMD} ${INSTALL_PATH} xgpd10"
    echo ""
    
    # Test basic functionality
    print_status "Testing basic functionality..."
    if ${PYTHON_CMD} ${INSTALL_PATH} -h >/dev/null 2>&1; then
        print_status "✓ Basic test passed!"
    else
        print_warning "Basic test failed. You may need to run with sudo for full functionality."
    fi
    
    # Check for vcgencmd
    if command -v vcgencmd >/dev/null 2>&1; then
        print_status "✓ vcgencmd found - full GPU monitoring available"
    else
        print_warning "vcgencmd not found - some GPU features may be limited"
    fi
    
    echo ""
    print_status "Installation complete! You can now run bcmstat."
    print_status "For Chinese documentation, visit: https://github.com/pplovebobo/bcmstat"
}

main "$@"
