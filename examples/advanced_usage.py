#!/usr/bin/env python3
"""
Advanced Usage Examples
Demonstrates advanced features of the terminal automation system
"""

import sys
sys.path.insert(0, '..')

from src.terminal_manager import TerminalManager


def example_cross_platform_script():
    """Example: Execute a script across multiple platforms"""
    print("=" * 60)
    print("Cross-Platform Script Execution")
    print("=" * 60)

    manager = TerminalManager()

    # Commands to execute (in Linux format)
    script_commands = [
        'pwd',
        'ls -la',
        'echo "Hello from automation"',
    ]

    # Execute on Linux
    print("\n--- Linux Execution ---")
    manager.set_current_terminal('linux')
    for cmd in script_commands:
        result = manager.execute(cmd)
        print(f"$ {cmd}")
        if result['success'] and result['output']:
            print(result['output'][:100])

    # Execute same commands on PowerShell (translated)
    print("\n--- PowerShell Execution (Translated) ---")
    for cmd in script_commands:
        result = manager.translate_and_execute(cmd, 'linux', 'powershell')
        print(f"Original: {result['original_command']}")
        print(f"Translated: {result['translated_command']}")
        if result['success']:
            print("✓ Success")
        print()


def example_path_conversion():
    """Example: Path conversion between systems"""
    print("=" * 60)
    print("Path Conversion Examples")
    print("=" * 60)

    from src.path_manager import PathManager

    pm = PathManager()

    # Unix to Windows
    unix_paths = [
        '/home/user/documents',
        '/mnt/c/Users/user/Documents',
        '/tmp/test.txt'
    ]

    print("\nUnix → Windows:")
    for path in unix_paths:
        converted = pm.convert_path(path, 'linux', 'powershell')
        print(f"  {path:35s} → {converted}")

    # Windows to Unix
    win_paths = [
        'C:\\Users\\user\\Documents',
        'D:\\Projects\\code',
        'C:\\Windows\\System32'
    ]

    print("\nWindows → Unix:")
    for path in win_paths:
        converted = pm.convert_path(path, 'powershell', 'linux')
        print(f"  {path:35s} → {converted}")


def example_command_chaining():
    """Example: Chain multiple commands"""
    print("=" * 60)
    print("Command Chaining")
    print("=" * 60)

    manager = TerminalManager()
    manager.set_current_terminal('linux')

    # Chain of operations
    operations = [
        ('Create temp directory', 'mkdir -p /tmp/automation_test'),
        ('Change to directory', 'cd /tmp/automation_test'),
        ('Create test file', 'echo "test content" > test.txt'),
        ('List files', 'ls -la'),
        ('Read file', 'cat test.txt'),
        ('Clean up', 'rm -rf /tmp/automation_test'),
    ]

    print("\nExecuting command chain:")
    for description, command in operations:
        print(f"\n{description}: {command}")
        result = manager.execute(command)
        if result['success']:
            print("✓ Success")
            if result['output']:
                print(f"Output: {result['output'].strip()}")
        else:
            print("✗ Failed")
            if result['error']:
                print(f"Error: {result['error'].strip()}")


def example_translation_matrix():
    """Example: Show translation matrix for common commands"""
    print("=" * 60)
    print("Command Translation Matrix")
    print("=" * 60)

    manager = TerminalManager()

    test_commands = [
        ('linux', 'ls -la'),
        ('linux', 'rm -rf /tmp/test'),
        ('linux', 'ps aux'),
        ('powershell', 'Get-ChildItem'),
        ('powershell', 'Remove-Item -Recurse'),
        ('macos', 'open file.txt'),
    ]

    systems = ['linux', 'macos', 'powershell', 'ios']

    for source, command in test_commands:
        print(f"\n'{command}' ({source}):")
        suggestions = manager.get_translation_suggestions(command, source)

        for target_system in systems:
            if target_system != source:
                translated = suggestions.get(target_system, command)
                print(f"  → {target_system:12s}: {translated}")


def example_environment_setup():
    """Example: Setup environment across systems"""
    print("=" * 60)
    print("Environment Setup")
    print("=" * 60)

    manager = TerminalManager()

    # Set environment variables
    print("\nSetting environment variables:")
    for system_name in manager.list_systems():
        terminal = manager.terminals[system_name]
        terminal.set_environment('TEST_VAR', 'test_value')
        terminal.set_environment('PROJECT_PATH', '/home/user/project')
        print(f"✓ {system_name:12s}: Environment configured")

    # Get environment info
    print("\nEnvironment status:")
    for system_name in manager.list_systems():
        terminal = manager.terminals[system_name]
        test_var = terminal.get_environment('TEST_VAR')
        print(f"  {system_name:12s}: TEST_VAR = {test_var}")


def example_error_handling():
    """Example: Error handling"""
    print("=" * 60)
    print("Error Handling")
    print("=" * 60)

    manager = TerminalManager()
    manager.set_current_terminal('linux')

    # Test commands (some will fail)
    test_commands = [
        'ls /nonexistent_directory',
        'cat /nonexistent_file.txt',
        'invalid_command_xyz',
        'ls',  # This should succeed
    ]

    print("\nTesting error handling:")
    for cmd in test_commands:
        result = manager.execute(cmd)
        status = "✓" if result['success'] else "✗"
        print(f"\n{status} Command: {cmd}")
        print(f"  Exit code: {result['exit_code']}")

        if result['success']:
            print(f"  Output: {result['output'][:50]}...")
        else:
            print(f"  Error: {result['error'][:100]}")


def example_history_management():
    """Example: Command history management"""
    print("=" * 60)
    print("History Management")
    print("=" * 60)

    manager = TerminalManager()
    manager.set_current_terminal('linux')

    # Execute some commands
    commands = ['ls', 'pwd', 'echo test', 'date']

    print("\nExecuting commands:")
    for cmd in commands:
        manager.execute(cmd)
        print(f"  ✓ {cmd}")

    # View history
    print("\nCommand history:")
    history = manager.get_command_history()
    for i, cmd in enumerate(history, 1):
        print(f"  {i}. {cmd}")

    # Clear history
    print("\nClearing history...")
    manager.clear_history()

    print("History after clear:")
    history = manager.get_command_history()
    print(f"  Commands in history: {len(history)}")


def main():
    """Run all advanced examples"""
    examples = [
        example_cross_platform_script,
        example_path_conversion,
        example_command_chaining,
        example_translation_matrix,
        example_environment_setup,
        example_error_handling,
        example_history_management,
    ]

    for example in examples:
        try:
            example()
            print("\n" + "=" * 60 + "\n")
        except Exception as e:
            print(f"\nError in {example.__name__}: {e}\n")


if __name__ == "__main__":
    main()
