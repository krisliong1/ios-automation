#!/usr/bin/env python3
"""
Basic Usage Examples
Demonstrates basic functionality of the terminal automation system
"""

import sys
sys.path.insert(0, '..')

from src.terminal_manager import TerminalManager


def example_1_basic_execution():
    """Example 1: Execute commands on current system"""
    print("=" * 60)
    print("Example 1: Basic Command Execution")
    print("=" * 60)

    manager = TerminalManager()
    manager.set_current_terminal('linux')

    # Execute a simple command
    result = manager.execute('ls -la')

    print(f"Command executed on: {result['system']}")
    print(f"Success: {result['success']}")
    print(f"Output preview: {result['output'][:200]}...")
    print()


def example_2_translation():
    """Example 2: Translate commands between systems"""
    print("=" * 60)
    print("Example 2: Command Translation")
    print("=" * 60)

    manager = TerminalManager()

    # Translate Linux command to PowerShell
    result = manager.translate_and_execute('ls -la', 'linux', 'powershell')

    print(f"Original command (Linux): {result['original_command']}")
    print(f"Translated command (PowerShell): {result['translated_command']}")
    print()


def example_3_path_management():
    """Example 3: Path management"""
    print("=" * 60)
    print("Example 3: Path Management")
    print("=" * 60)

    manager = TerminalManager()

    # Change directory
    manager.change_directory('/tmp')

    # Get current paths
    print("Current path (Linux):", manager.get_current_path('linux'))
    print("Current path (macOS):", manager.get_current_path('macos'))
    print()


def example_4_common_commands():
    """Example 4: View common commands"""
    print("=" * 60)
    print("Example 4: Common Commands")
    print("=" * 60)

    manager = TerminalManager()
    commands = manager.get_common_commands()

    # Show a few common commands
    for cmd_name in ['list_files', 'change_directory', 'remove_file']:
        print(f"\n{cmd_name}:")
        for system, cmd in commands[cmd_name].items():
            print(f"  {system:12s}: {cmd}")

    print()


def example_5_translation_suggestions():
    """Example 5: Get translation suggestions"""
    print("=" * 60)
    print("Example 5: Translation Suggestions")
    print("=" * 60)

    manager = TerminalManager()

    # Get suggestions for a Linux command
    suggestions = manager.get_translation_suggestions('ls -la', 'linux')

    print("Translations of 'ls -la' from Linux:")
    for system, translated in suggestions.items():
        print(f"  {system:12s}: {translated}")

    print()


def example_6_system_info():
    """Example 6: System information"""
    print("=" * 60)
    print("Example 6: System Information")
    print("=" * 60)

    manager = TerminalManager()
    status = manager.get_status()

    print(f"Current system: {status['current_system']}")
    print(f"Available systems: {', '.join(status['available_systems'])}")
    print("\nCurrent paths:")
    for system, path in status['current_paths'].items():
        print(f"  {system:12s}: {path or 'Not set'}")

    print()


def main():
    """Run all examples"""
    examples = [
        example_1_basic_execution,
        example_2_translation,
        example_3_path_management,
        example_4_common_commands,
        example_5_translation_suggestions,
        example_6_system_info
    ]

    for example in examples:
        try:
            example()
        except Exception as e:
            print(f"Error in {example.__name__}: {e}")
            print()


if __name__ == "__main__":
    main()
