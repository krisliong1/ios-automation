"""
Linux Terminal System
Implementation for Linux bash terminal
"""

import subprocess
from typing import Dict
from .terminal_base import TerminalSystem


class LinuxTerminal(TerminalSystem):
    """Linux Terminal System (bash)"""

    def __init__(self):
        super().__init__("Linux Terminal", "linux")
        self.shell = "/bin/bash"

    def execute_command(self, command: str) -> Dict[str, any]:
        """Execute a command on Linux terminal"""
        try:
            self.add_to_history(command)

            result = subprocess.run(
                command,
                shell=True,
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
        """Translate command from other systems to Linux format"""

        translations = {
            'powershell': {
                'Get-ChildItem': 'ls -la',
                'Set-Location': 'cd',
                'Remove-Item': 'rm -rf',
                'Copy-Item': 'cp -r',
                'Move-Item': 'mv',
                'Get-Content': 'cat',
                'Clear-Host': 'clear',
                'Get-Process': 'ps aux',
                'Stop-Process': 'kill -9',
                'Test-Path': 'test -e',
            },
            'macos': {
                'brew': 'apt-get',  # or yum depending on distro
                'launchctl': 'systemctl',
                'open': 'xdg-open',
            },
            'ios': {
                'ideviceinfo': 'uname -a',
                'idevicediagnostics': 'cat /proc/cpuinfo',
            }
        }

        if source_system == 'linux':
            return command

        translated = command

        if source_system in translations:
            for old_cmd, new_cmd in translations[source_system].items():
                if command.startswith(old_cmd):
                    translated = command.replace(old_cmd, new_cmd, 1)
                    break

        return translated

    def get_distro_info(self) -> str:
        """Get Linux distribution information"""
        try:
            result = self.execute_command("cat /etc/os-release")
            if result['success']:
                return result['output']
        except:
            pass
        return "Unknown Linux Distribution"
