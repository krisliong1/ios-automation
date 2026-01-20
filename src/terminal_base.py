"""
Base Terminal System
Defines the abstract interface for all terminal systems
"""

from abc import ABC, abstractmethod
from typing import Optional, Dict, List
from pathlib import Path


class TerminalSystem(ABC):
    """Abstract base class for all terminal systems"""

    def __init__(self, name: str, platform: str):
        self.name = name
        self.platform = platform
        self.current_path = Path.home()
        self.environment = {}
        self.command_history = []

    @abstractmethod
    def execute_command(self, command: str) -> Dict[str, any]:
        """
        Execute a command on this terminal system

        Args:
            command: The command to execute

        Returns:
            Dict with keys: 'success', 'output', 'error', 'exit_code'
        """
        pass

    @abstractmethod
    def translate_from(self, command: str, source_system: str) -> str:
        """
        Translate a command from another system to this system's format

        Args:
            command: The command to translate
            source_system: The source system type (macos, linux, ios, powershell)

        Returns:
            Translated command string
        """
        pass

    def change_directory(self, path: str) -> bool:
        """
        Change the current working directory

        Args:
            path: New directory path

        Returns:
            True if successful, False otherwise
        """
        try:
            new_path = Path(path)
            if not new_path.is_absolute():
                new_path = self.current_path / new_path

            new_path = new_path.resolve()

            if new_path.exists():
                self.current_path = new_path
                return True
            else:
                return False
        except Exception as e:
            print(f"Error changing directory: {e}")
            return False

    def get_current_path(self) -> str:
        """Get the current working directory"""
        return str(self.current_path)

    def set_environment(self, key: str, value: str):
        """Set an environment variable"""
        self.environment[key] = value

    def get_environment(self, key: str) -> Optional[str]:
        """Get an environment variable"""
        return self.environment.get(key)

    def add_to_history(self, command: str):
        """Add command to history"""
        self.command_history.append(command)

    def get_history(self) -> List[str]:
        """Get command history"""
        return self.command_history.copy()

    def clear_history(self):
        """Clear command history"""
        self.command_history.clear()

    def get_info(self) -> Dict[str, str]:
        """Get system information"""
        return {
            'name': self.name,
            'platform': self.platform,
            'current_path': str(self.current_path),
            'environment_vars': len(self.environment),
            'history_size': len(self.command_history)
        }
