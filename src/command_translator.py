"""
Command Translator
Handles cross-platform command translation between different terminal systems
"""

from typing import Dict, List, Tuple
from .terminal_base import TerminalSystem


class CommandTranslator:
    """Translates commands between different terminal systems"""

    def __init__(self):
        self.supported_systems = ['macos', 'linux', 'ios', 'powershell']

    def translate(self, command: str, source: str, target: str) -> str:
        """
        Translate a command from source system to target system

        Args:
            command: The command to translate
            source: Source system type
            target: Target system type

        Returns:
            Translated command string
        """
        if source not in self.supported_systems:
            raise ValueError(f"Unsupported source system: {source}")
        if target not in self.supported_systems:
            raise ValueError(f"Unsupported target system: {target}")

        if source == target:
            return command

        # Use comprehensive translation maps
        translation_map = self._get_translation_map(source, target)

        # Try to find matching translation
        translated = command
        for pattern, replacement in sorted(translation_map.items(), key=lambda x: len(x[0]), reverse=True):
            if command.startswith(pattern):
                # Replace the pattern and preserve the rest
                rest_of_command = command[len(pattern):]
                translated = replacement + rest_of_command
                break

        return translated

    def _get_translation_map(self, source: str, target: str) -> Dict[str, str]:
        """Get translation map from source to target system"""

        # Comprehensive translation mappings
        translations = {
            # Unix-like (Linux/macOS) to PowerShell
            ('linux', 'powershell'): {
                'ls -la': 'Get-ChildItem -Force',
                'ls -l': 'Get-ChildItem',
                'ls': 'Get-ChildItem',
                'cd': 'Set-Location',
                'pwd': 'Get-Location',
                'rm -rf': 'Remove-Item -Recurse -Force',
                'rm -r': 'Remove-Item -Recurse',
                'rm': 'Remove-Item',
                'cp -r': 'Copy-Item -Recurse',
                'cp': 'Copy-Item',
                'mv': 'Move-Item',
                'cat': 'Get-Content',
                'clear': 'Clear-Host',
                'ps aux': 'Get-Process',
                'ps': 'Get-Process',
                'kill -9': 'Stop-Process -Force',
                'kill': 'Stop-Process',
                'echo': 'Write-Output',
                'grep': 'Select-String',
                'find': 'Get-ChildItem -Recurse',
                'touch': 'New-Item -ItemType File',
                'mkdir': 'New-Item -ItemType Directory',
            },
            ('macos', 'powershell'): {
                'ls -la': 'Get-ChildItem -Force',
                'ls -l': 'Get-ChildItem',
                'ls': 'Get-ChildItem',
                'cd': 'Set-Location',
                'pwd': 'Get-Location',
                'rm -rf': 'Remove-Item -Recurse -Force',
                'rm': 'Remove-Item',
                'cp -r': 'Copy-Item -Recurse',
                'cp': 'Copy-Item',
                'mv': 'Move-Item',
                'cat': 'Get-Content',
                'clear': 'Clear-Host',
                'ps aux': 'Get-Process',
                'kill': 'Stop-Process',
                'open': 'Invoke-Item',
                'brew install': 'choco install',
                'brew': 'choco',
            },
            # PowerShell to Unix-like
            ('powershell', 'linux'): {
                'Get-ChildItem -Force': 'ls -la',
                'Get-ChildItem': 'ls',
                'Set-Location': 'cd',
                'Get-Location': 'pwd',
                'Remove-Item -Recurse -Force': 'rm -rf',
                'Remove-Item -Recurse': 'rm -r',
                'Remove-Item': 'rm',
                'Copy-Item -Recurse': 'cp -r',
                'Copy-Item': 'cp',
                'Move-Item': 'mv',
                'Get-Content': 'cat',
                'Clear-Host': 'clear',
                'Get-Process': 'ps aux',
                'Stop-Process -Force': 'kill -9',
                'Stop-Process': 'kill',
                'Write-Output': 'echo',
                'Select-String': 'grep',
                'New-Item -ItemType File': 'touch',
                'New-Item -ItemType Directory': 'mkdir',
            },
            ('powershell', 'macos'): {
                'Get-ChildItem -Force': 'ls -la',
                'Get-ChildItem': 'ls',
                'Set-Location': 'cd',
                'Get-Location': 'pwd',
                'Remove-Item -Recurse -Force': 'rm -rf',
                'Remove-Item': 'rm',
                'Copy-Item -Recurse': 'cp -r',
                'Copy-Item': 'cp',
                'Move-Item': 'mv',
                'Get-Content': 'cat',
                'Clear-Host': 'clear',
                'Get-Process': 'ps aux',
                'Stop-Process': 'kill',
                'Invoke-Item': 'open',
                'choco install': 'brew install',
                'choco': 'brew',
            },
            # Linux to macOS (mostly the same, but some differences)
            ('linux', 'macos'): {
                'apt-get install': 'brew install',
                'apt-get': 'brew',
                'yum install': 'brew install',
                'yum': 'brew',
                'systemctl': 'launchctl',
                'xdg-open': 'open',
            },
            ('macos', 'linux'): {
                'brew install': 'apt-get install',
                'brew': 'apt-get',
                'launchctl': 'systemctl',
                'open': 'xdg-open',
            },
            # iOS specific translations
            ('ios', 'macos'): {
                'ideviceinfo': 'system_profiler SPHardwareDataType',
                'idevicefs ls': 'ls',
                'idevicefs cat': 'cat',
            },
            ('macos', 'ios'): {
                'system_profiler': 'ideviceinfo',
                'ls': 'idevicefs ls',
                'cat': 'idevicefs cat',
            },
            ('ios', 'linux'): {
                'ideviceinfo': 'uname -a',
                'idevicefs ls': 'ls',
                'idevicefs cat': 'cat',
            },
            ('linux', 'ios'): {
                'uname': 'ideviceinfo',
                'ls': 'idevicefs ls',
                'cat': 'idevicefs cat',
            },
            ('ios', 'powershell'): {
                'ideviceinfo': 'Get-ComputerInfo',
                'idevicefs ls': 'Get-ChildItem',
                'idevicefs cat': 'Get-Content',
            },
            ('powershell', 'ios'): {
                'Get-ComputerInfo': 'ideviceinfo',
                'Get-ChildItem': 'idevicefs ls',
                'Get-Content': 'idevicefs cat',
            },
        }

        return translations.get((source, target), {})

    def get_common_commands(self) -> Dict[str, Dict[str, str]]:
        """
        Get common commands across all systems

        Returns:
            Dictionary mapping command names to their system-specific implementations
        """
        return {
            'list_files': {
                'linux': 'ls -la',
                'macos': 'ls -la',
                'ios': 'idevicefs ls',
                'powershell': 'Get-ChildItem -Force'
            },
            'change_directory': {
                'linux': 'cd',
                'macos': 'cd',
                'ios': 'cd',
                'powershell': 'Set-Location'
            },
            'print_working_directory': {
                'linux': 'pwd',
                'macos': 'pwd',
                'ios': 'pwd',
                'powershell': 'Get-Location'
            },
            'remove_file': {
                'linux': 'rm -rf',
                'macos': 'rm -rf',
                'ios': 'rm -rf',
                'powershell': 'Remove-Item -Recurse -Force'
            },
            'copy_file': {
                'linux': 'cp -r',
                'macos': 'cp -r',
                'ios': 'cp -r',
                'powershell': 'Copy-Item -Recurse'
            },
            'move_file': {
                'linux': 'mv',
                'macos': 'mv',
                'ios': 'mv',
                'powershell': 'Move-Item'
            },
            'read_file': {
                'linux': 'cat',
                'macos': 'cat',
                'ios': 'idevicefs cat',
                'powershell': 'Get-Content'
            },
            'clear_screen': {
                'linux': 'clear',
                'macos': 'clear',
                'ios': 'clear',
                'powershell': 'Clear-Host'
            },
            'list_processes': {
                'linux': 'ps aux',
                'macos': 'ps aux',
                'ios': 'ps aux',
                'powershell': 'Get-Process'
            }
        }

    def suggest_translation(self, command: str, source: str) -> Dict[str, str]:
        """
        Get translations of a command to all other systems

        Args:
            command: Command to translate
            source: Source system

        Returns:
            Dictionary of translations to all other systems
        """
        suggestions = {}
        for target in self.supported_systems:
            if target != source:
                suggestions[target] = self.translate(command, source, target)

        return suggestions
