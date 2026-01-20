#!/usr/bin/env python3
"""
Kris Automation Center - Unified System
Main entry point for the complete unified automation system

Features:
- Cross-platform terminal automation (macOS, Linux, iOS, Windows)
- AI Manager integration
- AI Fixer system
- iCloud automatic synchronization
- Real command execution with history tracking
"""

import os
import sys
import logging
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / 'src'))

from src.unified_terminal import UnifiedTerminalSystem


def setup_logging(log_level=logging.INFO):
    """Setup logging configuration"""
    logging.basicConfig(
        level=log_level,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.StreamHandler(sys.stdout),
            logging.FileHandler('unified_system.log')
        ]
    )


def print_banner():
    """Print system banner"""
    banner = """
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║              Kris Automation Center - Unified System                ║
║                                                                      ║
║  Cross-platform terminal automation with iCloud integration         ║
║  Supporting: macOS, Linux, iOS, Windows                             ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
"""
    print(banner)


def print_menu():
    """Print main menu"""
    print("\n" + "─" * 70)
    print("MAIN MENU")
    print("─" * 70)
    print("1. Execute command (current platform)")
    print("2. Execute on macOS")
    print("3. Execute on Linux")
    print("4. Execute on iOS")
    print("5. Execute on Windows (PowerShell)")
    print()
    print("6. View session history")
    print("7. View all sessions")
    print("8. Search history")
    print("9. View statistics")
    print()
    print("10. Sync to iCloud now")
    print("11. View iCloud status")
    print("12. System configuration")
    print()
    print("0. Exit")
    print("─" * 70)


def execute_command_interactive(system: UnifiedTerminalSystem, platform=None):
    """Interactive command execution"""
    command = input("\nEnter command: ").strip()

    if not command:
        print("❌ No command provided")
        return

    print(f"\nExecuting: {command}")
    if platform:
        print(f"Platform: {platform}")

    result = system.execute_command(command, platform)

    print("\n" + "─" * 70)
    if result['success']:
        print("✅ SUCCESS")
    else:
        print("❌ FAILED")

    print(f"Exit Code: {result.get('exit_code', 'N/A')}")

    if result.get('output'):
        print(f"\nOutput:\n{result['output']}")

    if result.get('error'):
        print(f"\nError:\n{result['error']}")

    print("─" * 70)
    print(f"✅ Saved to iCloud: {system.icloud_root}/terminal-sessions/")


def view_session_history(system: UnifiedTerminalSystem):
    """View current session history"""
    history = system.get_session_history()

    if not history:
        print("\n❌ No active session")
        return

    print("\n" + "═" * 70)
    print(f"SESSION: {history['session_id']}")
    print("═" * 70)
    print(f"Platform: {history['platform']}")
    print(f"Created: {history['created_at']}")
    print(f"Commands: {len(history.get('commands', []))}")
    print()

    for i, cmd_entry in enumerate(history.get('commands', []), 1):
        print(f"{i}. {cmd_entry['timestamp']}")
        print(f"   Command: {cmd_entry['command']}")
        result = cmd_entry.get('result', {})
        if result.get('success'):
            print(f"   Status: ✅ Success")
        else:
            print(f"   Status: ❌ Failed")
        print()


def view_all_sessions(system: UnifiedTerminalSystem):
    """View all sessions"""
    sessions = system.get_all_sessions()

    if not sessions:
        print("\n❌ No sessions found")
        return

    print("\n" + "═" * 70)
    print(f"ALL SESSIONS ({len(sessions)} total)")
    print("═" * 70)

    for session in sessions[:20]:  # Show first 20
        print(f"\n{session['session_id']}")
        print(f"  Platform: {session['platform']}")
        print(f"  Created: {session['created_at']}")
        print(f"  Commands: {len(session.get('commands', []))}")


def search_history_interactive(system: UnifiedTerminalSystem):
    """Interactive history search"""
    query = input("\nSearch query: ").strip()

    if not query:
        print("❌ No query provided")
        return

    print(f"\nSearching for: {query}")

    results = system.search_history(query)

    if not results:
        print("❌ No results found")
        return

    print(f"\n✅ Found {len(results)} results")
    print("═" * 70)

    for i, result in enumerate(results[:10], 1):  # Show first 10
        print(f"\n{i}. {result['timestamp']}")
        print(f"   Platform: {result['platform']}")
        print(f"   Command: {result['command']}")
        print(f"   Session: {result['session_id']}")


def view_statistics(system: UnifiedTerminalSystem):
    """View system statistics"""
    stats = system.get_statistics()

    print("\n" + "═" * 70)
    print("SYSTEM STATISTICS")
    print("═" * 70)
    print(f"Total Sessions: {stats['total_sessions']}")
    print(f"Total Commands: {stats['total_commands']}")
    print(f"\nPlatform Distribution:")

    for platform, count in stats['platform_distribution'].items():
        print(f"  {platform}: {count} sessions")

    print(f"\niCloud Root: {stats['icloud_root']}")


def view_config(system: UnifiedTerminalSystem):
    """View system configuration"""
    config = system.config

    print("\n" + "═" * 70)
    print("SYSTEM CONFIGURATION")
    print("═" * 70)
    print(f"System Name: {config.get('system_name')}")
    print(f"Version: {config.get('version')}")
    print(f"\niCloud Root: {system.icloud_root}")

    print("\nEnabled Platforms:")
    for platform, settings in config.get('terminals', {}).items():
        enabled = "✅" if settings.get('enabled') else "❌"
        print(f"  {enabled} {platform}")


def main():
    """Main function"""
    # Setup
    setup_logging()
    print_banner()

    # Get iCloud root
    default_icloud = "~/Library/Mobile Documents/com~apple~CloudDocs/kris-server"
    icloud_root = os.environ.get('ICLOUD_ROOT', default_icloud)

    print(f"\niCloud Root: {icloud_root}")
    print("Initializing system...")

    try:
        # Initialize unified system
        system = UnifiedTerminalSystem(icloud_root)

        print("✅ System initialized successfully!")
        print(f"✅ All commands will be saved to iCloud automatically")

        # Start default session
        session_id = system.start_session(platform="linux")
        print(f"✅ Started session: {session_id}")

        # Main loop
        while True:
            print_menu()

            try:
                choice = input("Select option: ").strip()

                if choice == "1":
                    execute_command_interactive(system)

                elif choice == "2":
                    execute_command_interactive(system, platform="macos")

                elif choice == "3":
                    execute_command_interactive(system, platform="linux")

                elif choice == "4":
                    execute_command_interactive(system, platform="ios")

                elif choice == "5":
                    execute_command_interactive(system, platform="powershell")

                elif choice == "6":
                    view_session_history(system)

                elif choice == "7":
                    view_all_sessions(system)

                elif choice == "8":
                    search_history_interactive(system)

                elif choice == "9":
                    view_statistics(system)

                elif choice == "10":
                    print("\nSyncing to iCloud...")
                    system.sync_engine.auto_sync(
                        str(Path.cwd()),
                        "ios-automation"
                    )
                    print("✅ Sync complete!")

                elif choice == "11":
                    status = system.sync_engine.get_sync_status()
                    print("\niCloud Sync Status:")
                    if status.get('syncs'):
                        last = status['syncs'][-1]
                        print(f"  Last sync: {last['last_sync']}")
                        print(f"  Path: {last['path']}")
                        print(f"  Status: {last['status']}")
                    else:
                        print("  No sync history")

                elif choice == "12":
                    view_config(system)

                elif choice == "0":
                    print("\n👋 Goodbye!")
                    print(f"All data saved to: {system.icloud_root}")
                    break

                else:
                    print("\n❌ Invalid option")

                input("\nPress Enter to continue...")

            except KeyboardInterrupt:
                print("\n\n👋 Interrupted. Exiting...")
                break

            except Exception as e:
                print(f"\n❌ Error: {e}")
                logging.exception("Error in main loop")
                input("\nPress Enter to continue...")

    except Exception as e:
        print(f"\n❌ Failed to initialize system: {e}")
        logging.exception("Initialization error")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
