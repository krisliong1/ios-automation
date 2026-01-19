"""
Terminal Manager
Main interface for managing multiple terminal systems and translating commands
"""

from typing import Dict, Optional, List
from .terminal_base import TerminalSystem
from .macos_terminal import MacOSTerminal
from .linux_terminal import LinuxTerminal
from .ios_terminal import IOSTerminal
from .powershell_terminal import PowerShellTerminal
from .command_translator import CommandTranslator
from .path_manager import PathManager


class TerminalManager:
    """
    Central manager for all terminal systems
    Provides unified interface for multi-platform terminal automation
    """

    def __init__(self):
        self.terminals: Dict[str, TerminalSystem] = {
            'macos': MacOSTerminal(),
            'linux': LinuxTerminal(),
            'ios': IOSTerminal(),
            'powershell': PowerShellTerminal()
        }
        self.translator = CommandTranslator()
        self.path_manager = PathManager()
        self.current_terminal = 'linux'  # Default to Linux

    def set_current_terminal(self, system: str):
        """Set the active terminal system"""
        if system not in self.terminals:
            raise ValueError(f"Unknown terminal system: {system}")
        self.current_terminal = system
        self.path_manager.set_current_system(system)

    def get_current_terminal(self) -> TerminalSystem:
        """Get the currently active terminal"""
        return self.terminals[self.current_terminal]

    def execute(self, command: str, system: Optional[str] = None) -> Dict[str, any]:
        """
        Execute a command on a specific terminal system

        Args:
            command: Command to execute
            system: Target system (uses current if None)

        Returns:
            Execution result dictionary
        """
        target_system = system or self.current_terminal
        terminal = self.terminals[target_system]

        result = terminal.execute_command(command)
        result['system'] = target_system

        return result

    def translate_and_execute(self, command: str, source: str, target: str) -> Dict[str, any]:
        """
        Translate a command from source system to target system and execute it

        Args:
            command: Command in source system format
            source: Source system name
            target: Target system name

        Returns:
            Execution result with translation info
        """
        # Translate command
        translated = self.translator.translate(command, source, target)

        # Execute on target system
        result = self.execute(translated, target)
        result['original_command'] = command
        result['translated_command'] = translated
        result['source_system'] = source
        result['target_system'] = target

        return result

    def execute_on_all(self, command: str, source: str) -> Dict[str, Dict]:
        """
        Execute a command on all terminal systems (translated from source)

        Args:
            command: Command in source system format
            source: Source system name

        Returns:
            Dictionary mapping system names to their execution results
        """
        results = {}

        for system_name in self.terminals.keys():
            try:
                result = self.translate_and_execute(command, source, system_name)
                results[system_name] = result
            except Exception as e:
                results[system_name] = {
                    'success': False,
                    'error': str(e),
                    'system': system_name
                }

        return results

    def change_directory(self, path: str, system: Optional[str] = None) -> bool:
        """
        Change directory on a specific terminal

        Args:
            path: Directory path
            system: Target system (uses current if None)

        Returns:
            True if successful
        """
        target_system = system or self.current_terminal
        terminal = self.terminals[target_system]

        success = terminal.change_directory(path)

        if success:
            # Update path manager
            self.path_manager.set_path(target_system, terminal.get_current_path())

        return success

    def get_current_path(self, system: Optional[str] = None) -> str:
        """Get current working directory of a terminal"""
        target_system = system or self.current_terminal
        return self.terminals[target_system].get_current_path()

    def sync_paths(self, base_system: Optional[str] = None):
        """
        Synchronize paths across all terminals based on current terminal's path

        Args:
            base_system: Base system to sync from (uses current if None)
        """
        base = base_system or self.current_terminal
        base_path = self.get_current_path(base)

        self.path_manager.sync_paths(base_path, base)

        # Apply converted paths to each terminal
        for system_name, terminal in self.terminals.items():
            if system_name != base:
                converted_path = self.path_manager.get_path(system_name)
                if converted_path:
                    terminal.change_directory(str(converted_path))

    def get_translation_suggestions(self, command: str, source: str) -> Dict[str, str]:
        """Get translations of a command to all other systems"""
        return self.translator.suggest_translation(command, source)

    def get_common_commands(self) -> Dict[str, Dict[str, str]]:
        """Get common commands across all systems"""
        return self.translator.get_common_commands()

    def get_terminal_info(self, system: Optional[str] = None) -> Dict[str, any]:
        """Get information about a terminal system"""
        target_system = system or self.current_terminal
        return self.terminals[target_system].get_info()

    def get_all_terminal_info(self) -> Dict[str, Dict]:
        """Get information about all terminal systems"""
        return {
            name: terminal.get_info()
            for name, terminal in self.terminals.items()
        }

    def get_command_history(self, system: Optional[str] = None) -> List[str]:
        """Get command history for a terminal"""
        target_system = system or self.current_terminal
        return self.terminals[target_system].get_history()

    def clear_history(self, system: Optional[str] = None):
        """Clear command history for a terminal"""
        target_system = system or self.current_terminal
        self.terminals[target_system].clear_history()

    def list_systems(self) -> List[str]:
        """Get list of available terminal systems"""
        return list(self.terminals.keys())

    def get_status(self) -> Dict[str, any]:
        """Get overall status of the terminal manager"""
        return {
            'current_system': self.current_terminal,
            'available_systems': self.list_systems(),
            'current_paths': self.path_manager.get_all_paths(),
            'terminals': self.get_all_terminal_info()
        }
