"""
macOS Terminal System
Implementation for macOS bash/zsh terminal
"""

import subprocess
from typing import Dict
from .terminal_base import TerminalSystem


class MacOSTerminal(TerminalSystem):
    """macOS Terminal System (bash/zsh)"""

    def __init__(self):
        super().__init__("macOS Terminal", "darwin")
        self.shell = "/bin/zsh"  # Default shell for modern macOS

    def execute_command(self, command: str) -> Dict[str, any]:
        """Execute a command on macOS terminal"""
        try:
            self.add_to_history(command)

            # Execute command with current working directory
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
        """Translate command from other systems to macOS format"""

        # Command translation mappings
        translations = {
            'powershell': {
                'Get-ChildItem': 'ls -la',
                'Set-Location': 'cd',
                'Remove-Item': 'rm',
                'Copy-Item': 'cp',
                'Move-Item': 'mv',
                'Get-Content': 'cat',
                'Clear-Host': 'clear',
                'Get-Process': 'ps aux',
                'Stop-Process': 'kill',
            },
            'linux': {
                # Most Linux commands work on macOS
                'apt-get': 'brew',
                'yum': 'brew',
                'systemctl': 'launchctl',
            },
            'ios': {
                # iOS to macOS translations
                'ideviceinfo': 'system_profiler SPHardwareDataType',
                'idevicediagnostics': 'system_profiler',
            }
        }

        if source_system == 'macos':
            return command

        translated = command

        if source_system in translations:
            for old_cmd, new_cmd in translations[source_system].items():
                if command.startswith(old_cmd):
                    translated = command.replace(old_cmd, new_cmd, 1)
                    break

        return translated

    def get_system_info(self) -> Dict[str, str]:
        """Get macOS system information"""
        info = self.get_info()

        # Add macOS-specific info
        try:
            result = self.execute_command("sw_vers")
            if result['success']:
                info['system_version'] = result['output'].strip()
        except:
            pass

        return info
