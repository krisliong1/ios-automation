"""
PowerShell Terminal System
Implementation for Windows PowerShell
"""

import subprocess
from typing import Dict
from .terminal_base import TerminalSystem


class PowerShellTerminal(TerminalSystem):
    """PowerShell Terminal System (Windows)"""

    def __init__(self):
        super().__init__("PowerShell", "win32")
        self.shell = "powershell.exe"

    def execute_command(self, command: str) -> Dict[str, any]:
        """Execute a command on PowerShell"""
        try:
            self.add_to_history(command)

            # Execute PowerShell command
            ps_command = [
                "powershell.exe",
                "-NoProfile",
                "-NonInteractive",
                "-Command",
                command
            ]

            result = subprocess.run(
                ps_command,
                cwd=str(self.current_path),
                capture_output=True,
                text=True,
                timeout=30
            )

            return {
                'success': result.returncode == 0,
                'output': result.stdout,
                'error': result.stderr,
                'exit_code': result.returncode
            }
        except subprocess.TimeoutExpired:
            return {
                'success': False,
                'output': '',
                'error': 'Command timed out',
                'exit_code': -1
            }
        except Exception as e:
            return {
                'success': False,
                'output': '',
                'error': str(e),
                'exit_code': -1
            }

    def translate_from(self, command: str, source_system: str) -> str:
        """Translate command from other systems to PowerShell format"""

        translations = {
            'linux': {
                'ls': 'Get-ChildItem',
                'ls -la': 'Get-ChildItem -Force',
                'cd': 'Set-Location',
                'rm': 'Remove-Item',
                'rm -rf': 'Remove-Item -Recurse -Force',
                'cp': 'Copy-Item',
                'cp -r': 'Copy-Item -Recurse',
                'mv': 'Move-Item',
                'cat': 'Get-Content',
                'clear': 'Clear-Host',
                'ps aux': 'Get-Process',
                'kill': 'Stop-Process',
                'pwd': 'Get-Location',
                'echo': 'Write-Output',
                'grep': 'Select-String',
                'find': 'Get-ChildItem -Recurse',
                'chmod': 'icacls',
                'touch': 'New-Item -ItemType File',
            },
            'macos': {
                'ls': 'Get-ChildItem',
                'ls -la': 'Get-ChildItem -Force',
                'cd': 'Set-Location',
                'rm': 'Remove-Item',
                'rm -rf': 'Remove-Item -Recurse -Force',
                'cp': 'Copy-Item',
                'mv': 'Move-Item',
                'cat': 'Get-Content',
                'clear': 'Clear-Host',
                'ps aux': 'Get-Process',
                'kill': 'Stop-Process',
                'open': 'Invoke-Item',
                'brew': 'choco',  # Chocolatey package manager
            },
            'ios': {
                'ideviceinfo': 'Get-ComputerInfo',
                'idevicefs ls': 'Get-ChildItem',
            }
        }

        if source_system == 'powershell':
            return command

        translated = command

        if source_system in translations:
            # Try longest matches first
            sorted_translations = sorted(
                translations[source_system].items(),
                key=lambda x: len(x[0]),
                reverse=True
            )

            for old_cmd, new_cmd in sorted_translations:
                if command.startswith(old_cmd):
                    translated = command.replace(old_cmd, new_cmd, 1)
                    break

        return translated
