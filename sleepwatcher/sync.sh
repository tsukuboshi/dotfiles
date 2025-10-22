#!/bin/bash

# sleepwatcherの設定を取得する関数
get_sleepwatcher_config() {
    local blueutil_path
    blueutil_path=$(which blueutil)

    if [ -z "$blueutil_path" ]; then
        echo ""
    else
        echo "$blueutil_path"
    fi
}

# 使用方法の表示
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  -s, --create-sleep-only    スリープスクリプト(~/.sleep)のみ作成"
    echo "  -w, --create-wakeup-only   起動スクリプト(~/.wakeup)のみ作成"
    echo "  -r, --restart-service-only sleepwatcherサービスの再起動のみ実行"
    echo "  (no option)                全て実行 (default)"
    echo ""
    echo "Examples:"
    echo "  $0                         # 全てのセットアップを実行"
    echo "  $0 --create-sleep-only     # スリープスクリプトのみ作成"
    echo "  $0 --create-wakeup-only    # 起動スクリプトのみ作成"
    echo "  $0 --restart-service-only  # サービスの再起動のみ実行"
    echo "  $0 -s                      # スリープスクリプトのみ作成(短縮)"
    echo "  $0 -w                      # 起動スクリプトのみ作成(短縮)"
    echo "  $0 -r                      # サービスの再起動のみ実行(短縮)"
}

# スリープスクリプトの作成
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

# 起動スクリプトの作成
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

# sleepwatcherサービスの再起動
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

# 引数の解析
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

# セットアップ実行
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
