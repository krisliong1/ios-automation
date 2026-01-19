#!/usr/bin/env python3
"""
iOS Automation - Cross-Platform Terminal System
Main application entry point
"""

import sys
from src.terminal_manager import TerminalManager


def print_header():
    """Print application header"""
    print("=" * 60)
    print("iOS Automation - Cross-Platform Terminal System")
    print("Multi-system terminal with command translation")
    print("=" * 60)
    print()


def print_menu():
    """Print main menu"""
    print("\n--- Main Menu ---")
    print("1. Execute command on current system")
    print("2. Translate and execute command")
    print("3. Execute on all systems")
    print("4. Change directory")
    print("5. Switch terminal system")
    print("6. View translation suggestions")
    print("7. View common commands")
    print("8. View system information")
    print("9. View command history")
    print("10. View status")
    print("0. Exit")
    print()


def execute_command(manager: TerminalManager):
    """Execute a command on current system"""
    command = input("Enter command: ").strip()
    if not command:
        return

    print(f"\nExecuting on {manager.current_terminal}...")
    result = manager.execute(command)

    print(f"\nSuccess: {result['success']}")
    if result['output']:
        print(f"Output:\n{result['output']}")
    if result['error']:
        print(f"Error:\n{result['error']}")
    print(f"Exit Code: {result['exit_code']}")


def translate_and_execute(manager: TerminalManager):
    """Translate and execute command"""
    command = input("Enter command: ").strip()
    if not command:
        return

    print("\nAvailable systems:", ", ".join(manager.list_systems()))
    source = input("Source system: ").strip().lower()
    target = input("Target system: ").strip().lower()

    if source not in manager.list_systems() or target not in manager.list_systems():
        print("Invalid system name!")
        return

    print(f"\nTranslating from {source} to {target}...")
    result = manager.translate_and_execute(command, source, target)

    print(f"\nOriginal: {result['original_command']}")
    print(f"Translated: {result['translated_command']}")
    print(f"Success: {result['success']}")
    if result['output']:
        print(f"Output:\n{result['output']}")
    if result['error']:
        print(f"Error:\n{result['error']}")


def execute_on_all(manager: TerminalManager):
    """Execute command on all systems"""
    command = input("Enter command: ").strip()
    if not command:
        return

    print("\nAvailable systems:", ", ".join(manager.list_systems()))
    source = input("Source system: ").strip().lower()

    if source not in manager.list_systems():
        print("Invalid system name!")
        return

    print(f"\nExecuting on all systems (translating from {source})...\n")
    results = manager.execute_on_all(command, source)

    for system, result in results.items():
        print(f"\n--- {system.upper()} ---")
        if 'translated_command' in result:
            print(f"Command: {result['translated_command']}")
        print(f"Success: {result['success']}")
        if result.get('output'):
            print(f"Output: {result['output'][:200]}...")  # Truncate long output
        if result.get('error'):
            print(f"Error: {result['error']}")


def change_directory(manager: TerminalManager):
    """Change directory"""
    path = input("Enter directory path: ").strip()
    if not path:
        return

    system = input(f"System (press Enter for current: {manager.current_terminal}): ").strip().lower()
    target = system if system else None

    success = manager.change_directory(path, target)

    if success:
        print(f"\nChanged directory to: {manager.get_current_path(target)}")
    else:
        print("\nFailed to change directory!")


def switch_system(manager: TerminalManager):
    """Switch terminal system"""
    print("\nAvailable systems:", ", ".join(manager.list_systems()))
    print(f"Current system: {manager.current_terminal}")

    system = input("\nSelect system: ").strip().lower()

    if system in manager.list_systems():
        manager.set_current_terminal(system)
        print(f"\nSwitched to {system}")
    else:
        print("\nInvalid system name!")


def view_suggestions(manager: TerminalManager):
    """View translation suggestions"""
    command = input("Enter command: ").strip()
    if not command:
        return

    print("\nAvailable systems:", ", ".join(manager.list_systems()))
    source = input("Source system: ").strip().lower()

    if source not in manager.list_systems():
        print("Invalid system name!")
        return

    suggestions = manager.get_translation_suggestions(command, source)

    print(f"\nTranslations from {source}:")
    for system, translated in suggestions.items():
        print(f"  {system:12s}: {translated}")


def view_common_commands(manager: TerminalManager):
    """View common commands"""
    commands = manager.get_common_commands()

    print("\nCommon Commands Across Systems:")
    for cmd_name, implementations in commands.items():
        print(f"\n{cmd_name}:")
        for system, cmd in implementations.items():
            print(f"  {system:12s}: {cmd}")


def view_system_info(manager: TerminalManager):
    """View system information"""
    system = input(f"System (press Enter for current: {manager.current_terminal}): ").strip().lower()
    target = system if system else None

    info = manager.get_terminal_info(target)

    print(f"\nSystem Information ({info['platform']}):")
    for key, value in info.items():
        print(f"  {key:20s}: {value}")


def view_history(manager: TerminalManager):
    """View command history"""
    system = input(f"System (press Enter for current: {manager.current_terminal}): ").strip().lower()
    target = system if system else None

    history = manager.get_command_history(target)

    print(f"\nCommand History ({target or manager.current_terminal}):")
    if history:
        for i, cmd in enumerate(history, 1):
            print(f"  {i}. {cmd}")
    else:
        print("  (empty)")


def view_status(manager: TerminalManager):
    """View overall status"""
    status = manager.get_status()

    print("\n=== System Status ===")
    print(f"Current System: {status['current_system']}")
    print(f"Available Systems: {', '.join(status['available_systems'])}")

    print("\nCurrent Paths:")
    for system, path in status['current_paths'].items():
        print(f"  {system:12s}: {path or 'Not set'}")

    print("\nTerminal Info:")
    for system, info in status['terminals'].items():
        print(f"  {system:12s}: {info['current_path']} ({info['history_size']} commands in history)")


def interactive_mode():
    """Run interactive mode"""
    print_header()

    manager = TerminalManager()

    # Set default to Linux (current environment)
    manager.set_current_terminal('linux')

    print(f"Current system: {manager.current_terminal}")
    print(f"Current path: {manager.get_current_path()}")

    while True:
        try:
            print_menu()
            choice = input("Select option: ").strip()

            if choice == '0':
                print("\nExiting...")
                break
            elif choice == '1':
                execute_command(manager)
            elif choice == '2':
                translate_and_execute(manager)
            elif choice == '3':
                execute_on_all(manager)
            elif choice == '4':
                change_directory(manager)
            elif choice == '5':
                switch_system(manager)
            elif choice == '6':
                view_suggestions(manager)
            elif choice == '7':
                view_common_commands(manager)
            elif choice == '8':
                view_system_info(manager)
            elif choice == '9':
                view_history(manager)
            elif choice == '10':
                view_status(manager)
            else:
                print("\nInvalid option!")

        except KeyboardInterrupt:
            print("\n\nExiting...")
            break
        except Exception as e:
            print(f"\nError: {e}")


def main():
    """Main entry point"""
    if len(sys.argv) > 1:
        # Command-line mode (future implementation)
        print("Command-line mode not yet implemented")
        print("Run without arguments for interactive mode")
    else:
        # Interactive mode
        interactive_mode()


if __name__ == "__main__":
    main()
