"""
Path Manager
Handles path management and conversion across different operating systems
"""

from pathlib import Path, PurePath, PurePosixPath, PureWindowsPath
from typing import Union, Dict, Optional


class PathManager:
    """Manages paths across different operating systems"""

    def __init__(self):
        self.paths = {
            'macos': None,
            'linux': None,
            'ios': None,
            'powershell': None
        }
        self.current_system = None

    def set_current_system(self, system: str):
        """Set the current operating system"""
        if system not in self.paths:
            raise ValueError(f"Unsupported system: {system}")
        self.current_system = system

    def set_path(self, system: str, path: Union[str, Path]):
        """
        Set the current path for a specific system

        Args:
            system: System name (macos, linux, ios, powershell)
            path: Path to set
        """
        if system not in self.paths:
            raise ValueError(f"Unsupported system: {system}")

        self.paths[system] = Path(path)

    def get_path(self, system: str) -> Optional[Path]:
        """Get the current path for a specific system"""
        return self.paths.get(system)

    def convert_path(self, path: str, from_system: str, to_system: str) -> str:
        """
        Convert a path from one system format to another

        Args:
            path: Path to convert
            from_system: Source system format
            to_system: Target system format

        Returns:
            Converted path string
        """
        # Handle Windows/PowerShell paths
        if from_system == 'powershell' and to_system in ['linux', 'macos', 'ios']:
            # Convert Windows path to Unix path
            # C:\Users\name\file -> /c/Users/name/file (Git Bash style)
            # or /mnt/c/Users/name/file (WSL style)
            win_path = PureWindowsPath(path)

            # Convert drive letter
            if win_path.drive:
                drive = win_path.drive[0].lower()
                path_without_drive = str(win_path.relative_to(win_path.drive + '\\'))
                unix_path = f"/mnt/{drive}/{path_without_drive}"
            else:
                unix_path = str(path).replace('\\', '/')

            return unix_path

        elif from_system in ['linux', 'macos', 'ios'] and to_system == 'powershell':
            # Convert Unix path to Windows path
            # /mnt/c/Users/name/file -> C:\Users\name\file
            # /c/Users/name/file -> C:\Users\name\file
            posix_path = PurePosixPath(path)

            # Check for WSL-style mount point
            if len(posix_path.parts) >= 3 and posix_path.parts[1] == 'mnt':
                drive = posix_path.parts[2].upper()
                rest = '/'.join(posix_path.parts[3:])
                win_path = f"{drive}:\\{rest}".replace('/', '\\')
            # Check for Git Bash-style mount point
            elif len(posix_path.parts) >= 2 and len(posix_path.parts[1]) == 1:
                drive = posix_path.parts[1].upper()
                rest = '/'.join(posix_path.parts[2:])
                win_path = f"{drive}:\\{rest}".replace('/', '\\')
            else:
                win_path = str(path).replace('/', '\\')

            return win_path

        # Unix to Unix conversions (mostly the same)
        return path

    def normalize_path(self, path: str, system: str) -> str:
        """
        Normalize a path for a specific system

        Args:
            path: Path to normalize
            system: Target system

        Returns:
            Normalized path string
        """
        if system == 'powershell':
            # Windows-style normalization
            return str(PureWindowsPath(path))
        else:
            # Unix-style normalization
            return str(PurePosixPath(path))

    def is_absolute(self, path: str, system: str) -> bool:
        """Check if a path is absolute for a given system"""
        if system == 'powershell':
            return PureWindowsPath(path).is_absolute()
        else:
            return PurePosixPath(path).is_absolute()

    def join_paths(self, *paths: str, system: str) -> str:
        """
        Join multiple path components for a specific system

        Args:
            *paths: Path components to join
            system: Target system

        Returns:
            Joined path string
        """
        if system == 'powershell':
            return str(PureWindowsPath(*paths))
        else:
            return str(PurePosixPath(*paths))

    def get_parent(self, path: str, system: str) -> str:
        """Get the parent directory of a path"""
        if system == 'powershell':
            return str(PureWindowsPath(path).parent)
        else:
            return str(PurePosixPath(path).parent)

    def get_name(self, path: str) -> str:
        """Get the name (filename) from a path"""
        return PurePath(path).name

    def get_extension(self, path: str) -> str:
        """Get the file extension from a path"""
        return PurePath(path).suffix

    def expand_home(self, path: str, system: str) -> str:
        """
        Expand ~ to home directory for a given system

        Args:
            path: Path potentially containing ~
            system: Target system

        Returns:
            Expanded path
        """
        if not path.startswith('~'):
            return path

        # Get home directory for each system
        home_dirs = {
            'linux': '/home',
            'macos': '/Users',
            'ios': '/var/mobile',
            'powershell': 'C:\\Users'
        }

        if system in home_dirs:
            # Simple expansion (in real implementation, would need username)
            return path.replace('~', home_dirs[system] + '/user', 1)

        return path

    def get_all_paths(self) -> Dict[str, Optional[str]]:
        """Get all current paths for all systems"""
        return {
            system: str(path) if path else None
            for system, path in self.paths.items()
        }

    def sync_paths(self, base_path: str, base_system: str):
        """
        Synchronize all system paths based on a base path

        Args:
            base_path: The base path to sync from
            base_system: The system of the base path
        """
        self.set_path(base_system, base_path)

        for system in self.paths:
            if system != base_system:
                converted = self.convert_path(base_path, base_system, system)
                self.set_path(system, converted)
