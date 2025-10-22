#!/bin/bash

# Get sleepwatcher configuration
get_sleepwatcher_config() {
    local blueutil_path
    blueutil_path=$(which blueutil)

    if [ -z "$blueutil_path" ]; then
        echo ""
    else
        echo "$blueutil_path"
    fi
}

# Show usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  -s, --create-sleep-only    Create sleep script (~/.sleep) only"
    echo "  -w, --create-wakeup-only   Create wakeup script (~/.wakeup) only"
    echo "  -r, --restart-service-only Restart sleepwatcher service only"
    echo "  (no option)                Execute all (default)"
    echo ""
    echo "Examples:"
    echo "  $0                         # Execute all setup"
    echo "  $0 --create-sleep-only     # Create sleep script only"
    echo "  $0 --create-wakeup-only    # Create wakeup script only"
    echo "  $0 --restart-service-only  # Restart service only"
    echo "  $0 -s                      # Create sleep script only (short)"
    echo "  $0 -w                      # Create wakeup script only (short)"
    echo "  $0 -r                      # Restart service only (short)"
}

# Create sleep script
create_sleep_script() {
    local blueutil_path
    blueutil_path=$(get_sleepwatcher_config)

    if [ -z "$blueutil_path" ]; then
        echo "blueutil command not found. Please install blueutil first."
        return 1
    fi

    echo "Creating sleep script (~/.sleep)..."
    echo "$blueutil_path -p 0" > ~/.sleep
    chmod 755 ~/.sleep
    echo "Sleep script created successfully."
}

# Create wakeup script
create_wakeup_script() {
    local blueutil_path
    blueutil_path=$(get_sleepwatcher_config)

    if [ -z "$blueutil_path" ]; then
        echo "blueutil command not found. Please install blueutil first."
        return 1
    fi

    echo "Creating wakeup script (~/.wakeup)..."
    echo "$blueutil_path -p 1" > ~/.wakeup
    chmod 755 ~/.wakeup
    echo "Wakeup script created successfully."
}

# Restart sleepwatcher service
restart_service() {
    if brew services info sleepwatcher &> /dev/null; then
        echo "Restarting sleepwatcher service..."
        brew services restart sleepwatcher
        echo "Sleepwatcher service restarted successfully."
    else
        echo "sleepwatcher not installed. Please install sleepwatcher using: brew install sleepwatcher"
        return 1
    fi
}

# Parse arguments
MODE="all"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            show_usage
            exit 0
            ;;
        --create-sleep-only|-s)
            MODE="sleep"
            shift
            ;;
        --create-wakeup-only|-w)
            MODE="wakeup"
            shift
            ;;
        --restart-service-only|-r)
            MODE="restart"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Execute setup
echo "Setting up sleepwatcher..."

case "$MODE" in
    sleep)
        create_sleep_script
        ;;
    wakeup)
        create_wakeup_script
        ;;
    restart)
        restart_service
        ;;
    *)
        create_sleep_script
        create_wakeup_script
        restart_service
        ;;
esac
