#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ランタイムの設定を取得する関数
get_runtime_config() {
    echo "${HOME}/.config/mise/config.toml"
}

# 使用方法の表示
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  -l, --link-config-only     config.tomlのリンクのみ実行"
    echo "  -i, --install-plugins-only mise pluginsのインストールのみ実行"
    echo "  (no option)                両方実行 (default)"
    echo ""
    echo "Examples:"
    echo "  $0                         # 設定とプラグインを両方セットアップ"
    echo "  $0 --link-config-only      # config.tomlのみリンク"
    echo "  $0 --install-plugins-only  # mise pluginsのみインストール"
    echo "  $0 -l                      # config.tomlのみリンク(短縮)"
    echo "  $0 -i                      # mise pluginsのみインストール(短縮)"
}

# config.tomlのリンク
link_config() {
    local runtime_config_path
    runtime_config_path=$(get_runtime_config)

    if [ ! -L "$runtime_config_path" ]; then
        echo "Linking config.toml to mise..."
        ln -fsvn "${SCRIPT_DIR}/config.toml" "$runtime_config_path"
    else
        echo "mise config.toml already linked."
    fi
}

# mise pluginsのインストール
install_plugins() {
    if command -v mise &> /dev/null; then
        echo "Installing mise plugins..."
        mise install
    else
        echo "mise command not found. Skipping plugins installation."
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
        --link-config-only|-l)
            MODE="link"
            shift
            ;;
        --install-plugins-only|-i)
            MODE="install"
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
echo "Setting up mise runtime..."

case "$MODE" in
    link)
        link_config
        ;;
    install)
        install_plugins
        ;;
    *)
        link_config
        install_plugins
        ;;
esac
