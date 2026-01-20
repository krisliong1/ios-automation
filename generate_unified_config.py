#!/usr/bin/env python3
"""
Generate Unified Configuration Files
Creates all necessary configuration files for the unified system
"""

import os
import json
from pathlib import Path


def generate_unified_config(icloud_root: str):
    """Generate main unified configuration file"""
    config = {
        "version": "1.0.0",
        "system_name": "Kris Automation Center",
        "icloud": {
            "enabled": True,
            "root_path": icloud_root,
            "sync_interval": 300,
            "auto_sync": True,
            "conflict_resolution": "keep_both"
        },
        "storage": {
            "primary": "icloud",
            "fallback": "local",
            "cache_enabled": True,
            "cache_size_mb": 500
        },
        "terminals": {
            "macos": {
                "enabled": True,
                "shell": "/bin/zsh",
                "working_dir": f"{icloud_root}/terminal-sessions/macos"
            },
            "linux": {
                "enabled": True,
                "shell": "/bin/bash",
                "working_dir": f"{icloud_root}/terminal-sessions/linux"
            },
            "ios": {
                "enabled": True,
                "working_dir": f"{icloud_root}/terminal-sessions/ios",
                "device_auto_detect": True
            },
            "windows": {
                "enabled": True,
                "shell": "powershell.exe",
                "working_dir": f"{icloud_root}/terminal-sessions/windows"
            }
        },
        "ai_systems": {
            "ai_manager": {
                "enabled": True,
                "config_path": f"{icloud_root}/ai-systems/ai-manager/config.json",
                "log_path": f"{icloud_root}/automation-logs/ai-manager"
            },
            "ai_fixer": {
                "enabled": True,
                "config_path": f"{icloud_root}/ai-systems/ai-fixer/config.json",
                "learning_data": f"{icloud_root}/ai-systems/ai-fixer/learning"
            },
            "claude_router": {
                "enabled": True,
                "config_path": f"{icloud_root}/ai-systems/claude-router/config.json",
                "providers": ["anthropic", "openrouter", "deepseek", "ollama", "gemini"]
            }
        },
        "logging": {
            "enabled": True,
            "level": "INFO",
            "path": f"{icloud_root}/automation-logs",
            "max_size_mb": 100,
            "rotation": "daily"
        },
        "security": {
            "encryption_enabled": True,
            "credentials_path": f"{icloud_root}/shared-config/credentials.encrypted.json",
            "api_keys_path": f"{icloud_root}/shared-config/api-keys.encrypted.json"
        }
    }

    return config


def generate_icloud_sync_config():
    """Generate iCloud sync configuration"""
    config = {
        "sync_rules": {
            "Sources/": {
                "priority": "high",
                "bidirectional": True,
                "conflict_resolution": "manual"
            },
            "src/": {
                "priority": "high",
                "bidirectional": True,
                "conflict_resolution": "manual"
            },
            "data/": {
                "priority": "medium",
                "bidirectional": True,
                "conflict_resolution": "latest"
            },
            "automation-logs/": {
                "priority": "low",
                "bidirectional": False,
                "upload_only": True
            },
            "terminal-sessions/": {
                "priority": "high",
                "bidirectional": True,
                "conflict_resolution": "timestamp"
            }
        },
        "exclude": [
            ".git/",
            "node_modules/",
            "__pycache__/",
            ".DS_Store",
            "*.pyc",
            "build/",
            ".build/"
        ],
        "bandwidth": {
            "max_upload_mbps": 10,
            "max_download_mbps": 20,
            "throttle_on_mobile": True
        }
    }

    return config


def generate_ai_manager_config(icloud_root: str):
    """Generate AI Manager configuration"""
    config = {
        "version": "1.0.0",
        "name": "AI Manager",
        "providers": {
            "anthropic": {
                "enabled": True,
                "model": "claude-sonnet-4",
                "api_key_env": "ANTHROPIC_API_KEY"
            },
            "openrouter": {
                "enabled": True,
                "model": "anthropic/claude-3.5-sonnet",
                "api_key_env": "OPENROUTER_API_KEY"
            },
            "deepseek": {
                "enabled": True,
                "model": "deepseek-chat",
                "api_key_env": "DEEPSEEK_API_KEY"
            },
            "ollama": {
                "enabled": True,
                "model": "llama3",
                "url": "http://localhost:11434"
            },
            "gemini": {
                "enabled": True,
                "model": "gemini-pro",
                "api_key_env": "GEMINI_API_KEY"
            }
        },
        "monitoring": {
            "health_check_interval": 30,
            "auto_switch_on_failure": True,
            "max_retries": 3
        },
        "logging": {
            "path": f"{icloud_root}/automation-logs/ai-manager",
            "level": "INFO"
        }
    }

    return config


def generate_ai_fixer_config(icloud_root: str):
    """Generate AI Fixer configuration"""
    config = {
        "version": "1.0.0",
        "name": "Kris AI Fixer",
        "learning": {
            "enabled": True,
            "data_path": f"{icloud_root}/ai-systems/ai-fixer/learning",
            "auto_save": True
        },
        "problem_types": [
            "network_error",
            "search_restricted",
            "api_quota",
            "timeout",
            "rate_limit",
            "authentication"
        ],
        "strategies": {
            "network_error": ["switch_provider", "configure_proxy", "retry"],
            "search_restricted": ["switch_search_engine", "use_alternative"],
            "api_quota": ["switch_provider", "wait_and_retry"],
            "timeout": ["increase_timeout", "retry"],
            "rate_limit": ["wait_and_retry", "switch_provider"]
        }
    }

    return config


def generate_claude_router_config(icloud_root: str):
    """Generate Claude Code Router configuration"""
    config = {
        "version": "1.0.0",
        "routes": {
            "default": {
                "provider": "anthropic",
                "model": "claude-sonnet-4"
            },
            "webSearch": {
                "provider": "openrouter",
                "model": "anthropic/claude-3.5-sonnet",
                "features": ["web-search"]
            },
            "background": {
                "provider": "deepseek",
                "model": "deepseek-chat",
                "temperature": 0.5
            },
            "think": {
                "provider": "anthropic",
                "model": "claude-opus-4",
                "max_tokens": 4096
            },
            "longContext": {
                "provider": "anthropic",
                "model": "claude-sonnet-4",
                "maxTokens": 200000
            },
            "local": {
                "provider": "ollama",
                "model": "llama3",
                "url": "http://localhost:11434"
            }
        },
        "fallback": {
            "enabled": True,
            "order": ["anthropic", "openrouter", "deepseek", "ollama"]
        }
    }

    return config


def create_directory_structure(icloud_root: Path):
    """Create iCloud directory structure"""
    directories = [
        "ios-automation",
        "ai-systems/ai-manager",
        "ai-systems/ai-fixer",
        "ai-systems/ai-fixer/learning",
        "ai-systems/claude-router",
        "ai-systems/models",
        "terminal-sessions/macos",
        "terminal-sessions/linux",
        "terminal-sessions/ios",
        "terminal-sessions/windows",
        "automation-logs/execution-history",
        "automation-logs/error-logs",
        "automation-logs/performance",
        "automation-logs/ai-manager",
        "automation-logs/ai-fixer",
        "shared-config",
        "sync-status",
        "sync-status/conflicts"
    ]

    for directory in directories:
        dir_path = icloud_root / directory
        dir_path.mkdir(parents=True, exist_ok=True)
        print(f"✅ Created: {dir_path}")


def save_config(config: dict, path: Path, name: str):
    """Save configuration file"""
    path.parent.mkdir(parents=True, exist_ok=True)

    with open(path, 'w') as f:
        json.dump(config, f, indent=2)

    print(f"✅ Generated: {name}")
    print(f"   Location: {path}")


def main():
    """Main function"""
    print("=" * 70)
    print("Unified System Configuration Generator")
    print("=" * 70)
    print()

    # Get iCloud root path
    default_icloud = "~/Library/Mobile Documents/com~apple~CloudDocs/kris-server"
    icloud_input = input(f"iCloud root path [{default_icloud}]: ").strip()
    icloud_root = Path(os.path.expanduser(icloud_input or default_icloud))

    print()
    print(f"iCloud Root: {icloud_root}")
    print()

    # Create directory structure
    print("Creating directory structure...")
    create_directory_structure(icloud_root)
    print()

    # Generate configurations
    print("Generating configuration files...")
    print()

    # 1. Main unified config
    unified_config = generate_unified_config(str(icloud_root))
    save_config(
        unified_config,
        icloud_root / "shared-config" / "unified-config.json",
        "Main Unified Configuration"
    )
    print()

    # 2. iCloud sync config
    sync_config = generate_icloud_sync_config()
    save_config(
        sync_config,
        icloud_root / "shared-config" / "icloud-sync.json",
        "iCloud Sync Configuration"
    )
    print()

    # 3. AI Manager config
    ai_manager_config = generate_ai_manager_config(str(icloud_root))
    save_config(
        ai_manager_config,
        icloud_root / "ai-systems" / "ai-manager" / "config.json",
        "AI Manager Configuration"
    )
    print()

    # 4. AI Fixer config
    ai_fixer_config = generate_ai_fixer_config(str(icloud_root))
    save_config(
        ai_fixer_config,
        icloud_root / "ai-systems" / "ai-fixer" / "config.json",
        "AI Fixer Configuration"
    )
    print()

    # 5. Claude Router config
    claude_router_config = generate_claude_router_config(str(icloud_root))
    save_config(
        claude_router_config,
        icloud_root / "ai-systems" / "claude-router" / "config.json",
        "Claude Router Configuration"
    )
    print()

    # Create README in iCloud root
    readme_content = f"""# Kris Server - Automation Center

This directory contains all data for the unified automation system.

## Directory Structure

- `ios-automation/` - Main iOS automation project
- `ai-systems/` - AI systems (AI Manager, AI Fixer, Claude Router)
- `terminal-sessions/` - Terminal session history (macOS, Linux, iOS, Windows)
- `automation-logs/` - All automation logs
- `shared-config/` - Shared configuration files
- `sync-status/` - Synchronization status

## Configuration

Main configuration file: `shared-config/unified-config.json`

## Last Updated

{Path(icloud_root / 'shared-config' / 'unified-config.json').stat().st_mtime if (icloud_root / 'shared-config' / 'unified-config.json').exists() else 'Not yet configured'}

## Usage

See the main repository for usage instructions:
https://github.com/krisliong1/ios-automation
"""

    readme_path = icloud_root / "README.md"
    with open(readme_path, 'w') as f:
        f.write(readme_content)

    print(f"✅ Created README: {readme_path}")
    print()

    print("=" * 70)
    print("✅ Configuration generation complete!")
    print("=" * 70)
    print()
    print("Next steps:")
    print(f"1. Review configurations in: {icloud_root}/shared-config/")
    print(f"2. Add API keys to environment variables")
    print(f"3. Run: python src/unified_terminal.py")
    print()
    print("All data will be automatically synced to iCloud! 🎉")
    print()


if __name__ == "__main__":
    main()
