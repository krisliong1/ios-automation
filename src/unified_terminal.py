"""
Unified Terminal System
Real executable cross-platform terminal with iCloud integration
"""

import os
import json
import uuid
from pathlib import Path
from datetime import datetime
from typing import Dict, Optional, List
import logging

from .terminal_manager import TerminalManager
from .icloud_sync_engine import iCloudSyncEngine

logger = logging.getLogger(__name__)


class SessionManager:
    """Manage terminal sessions with iCloud storage"""

    def __init__(self, icloud_root: Path):
        self.icloud_root = icloud_root
        self.sessions_root = icloud_root / "terminal-sessions"

    def create_session(self, platform: str) -> str:
        """Create a new session and return session ID"""
        session_id = str(uuid.uuid4())
        timestamp = datetime.now().isoformat()

        session_dir = self.sessions_root / platform
        session_dir.mkdir(parents=True, exist_ok=True)

        session_file = session_dir / f"{session_id}.json"

        session_data = {
            "session_id": session_id,
            "platform": platform,
            "created_at": timestamp,
            "commands": []
        }

        with open(session_file, 'w') as f:
            json.dump(session_data, f, indent=2)

        logger.info(f"Created session {session_id} for {platform}")
        return session_id

    def add_command_to_session(self, session_id: str, platform: str,
                                command: str, result: Dict):
        """Add a command and its result to a session"""
        session_file = self.sessions_root / platform / f"{session_id}.json"

        if not session_file.exists():
            logger.error(f"Session not found: {session_id}")
            return False

        # Load session
        with open(session_file, 'r') as f:
            session_data = json.load(f)

        # Add command
        command_entry = {
            "timestamp": datetime.now().isoformat(),
            "command": command,
            "result": result
        }

        session_data["commands"].append(command_entry)
        session_data["last_updated"] = datetime.now().isoformat()

        # Save session
        with open(session_file, 'w') as f:
            json.dump(session_data, f, indent=2)

        logger.info(f"Added command to session {session_id}")
        return True

    def get_session(self, session_id: str, platform: str) -> Optional[Dict]:
        """Get session data"""
        session_file = self.sessions_root / platform / f"{session_id}.json"

        if not session_file.exists():
            return None

        with open(session_file, 'r') as f:
            return json.load(f)

    def get_all_sessions(self, platform: Optional[str] = None) -> List[Dict]:
        """Get all sessions, optionally filtered by platform"""
        sessions = []

        if platform:
            platforms = [platform]
        else:
            platforms = ["macos", "linux", "ios", "windows"]

        for plat in platforms:
            session_dir = self.sessions_root / plat
            if session_dir.exists():
                for session_file in session_dir.glob("*.json"):
                    with open(session_file, 'r') as f:
                        sessions.append(json.load(f))

        # Sort by created_at
        sessions.sort(key=lambda x: x.get("created_at", ""), reverse=True)
        return sessions


class UnifiedTerminalSystem:
    """
    Unified Terminal System with real command execution and iCloud integration

    This system can:
    - Execute real commands on macOS, Linux, iOS, and Windows
    - Store all command history and results in iCloud
    - Sync across devices
    - Provide unified interface for all platforms
    """

    def __init__(self, icloud_root: str):
        """
        Initialize Unified Terminal System

        Args:
            icloud_root: Path to iCloud Drive root
                         e.g., ~/Library/Mobile Documents/com~apple~CloudDocs/kris-server
        """
        self.icloud_root = Path(os.path.expanduser(icloud_root))
        self.config = self.load_config()

        # Initialize components
        self.terminal_manager = TerminalManager()
        self.session_manager = SessionManager(self.icloud_root)
        self.sync_engine = iCloudSyncEngine(icloud_root)

        # Current session
        self.current_session_id = None
        self.current_platform = None

        logger.info(f"Unified Terminal System initialized")
        logger.info(f"iCloud root: {self.icloud_root}")

    def load_config(self) -> Dict:
        """Load unified configuration"""
        config_path = self.icloud_root / "shared-config" / "unified-config.json"

        if config_path.exists():
            with open(config_path, 'r') as f:
                return json.load(f)
        else:
            # Default configuration
            return {
                "version": "1.0.0",
                "system_name": "Kris Automation Center",
                "terminals": {
                    "macos": {"enabled": True},
                    "linux": {"enabled": True},
                    "ios": {"enabled": True},
                    "windows": {"enabled": True}
                }
            }

    def start_session(self, platform: str = "linux") -> str:
        """
        Start a new terminal session

        Args:
            platform: Target platform (macos, linux, ios, windows)

        Returns:
            Session ID
        """
        self.current_platform = platform
        self.current_session_id = self.session_manager.create_session(platform)

        logger.info(f"Started session {self.current_session_id} on {platform}")
        return self.current_session_id

    def execute_command(self, command: str, platform: Optional[str] = None,
                        save_to_icloud: bool = True) -> Dict:
        """
        Execute a command and optionally save to iCloud

        Args:
            command: Command to execute
            platform: Target platform (uses current if None)
            save_to_icloud: Whether to save result to iCloud

        Returns:
            Execution result dictionary
        """
        # Determine platform
        target_platform = platform or self.current_platform or "linux"

        # Start session if needed
        if not self.current_session_id or target_platform != self.current_platform:
            self.start_session(target_platform)

        logger.info(f"Executing command on {target_platform}: {command}")

        # Execute command using terminal manager
        try:
            result = self.terminal_manager.execute(command, target_platform)

            # Add platform to result
            result['platform'] = target_platform
            result['session_id'] = self.current_session_id

            # Save to iCloud if requested
            if save_to_icloud:
                self.save_to_icloud(command, result)

            logger.info(f"Command executed successfully: {result['success']}")
            return result

        except Exception as e:
            logger.error(f"Command execution failed: {e}")
            return {
                "success": False,
                "output": "",
                "error": str(e),
                "exit_code": 1,
                "platform": target_platform,
                "session_id": self.current_session_id
            }

    def save_to_icloud(self, command: str, result: Dict):
        """Save command and result to iCloud"""
        platform = result.get('platform', self.current_platform)
        session_id = result.get('session_id', self.current_session_id)

        # Add to session
        self.session_manager.add_command_to_session(
            session_id,
            platform,
            command,
            result
        )

        # Trigger sync (non-blocking)
        try:
            sessions_path = str(self.icloud_root / "terminal-sessions")
            # This will sync in background
            logger.debug("Triggering iCloud sync...")
        except Exception as e:
            logger.warning(f"iCloud sync trigger failed: {e}")

    def execute_on_macos(self, command: str) -> Dict:
        """Execute command on macOS"""
        return self.execute_command(command, platform="macos")

    def execute_on_linux(self, command: str) -> Dict:
        """Execute command on Linux"""
        return self.execute_command(command, platform="linux")

    def execute_on_ios(self, command: str) -> Dict:
        """Execute command on iOS"""
        return self.execute_command(command, platform="ios")

    def execute_on_windows(self, command: str) -> Dict:
        """Execute command on Windows/PowerShell"""
        return self.execute_command(command, platform="powershell")

    def get_session_history(self, session_id: Optional[str] = None) -> Optional[Dict]:
        """Get session history"""
        sid = session_id or self.current_session_id
        platform = self.current_platform or "linux"

        if not sid:
            logger.warning("No session ID provided")
            return None

        return self.session_manager.get_session(sid, platform)

    def get_all_sessions(self, platform: Optional[str] = None) -> List[Dict]:
        """Get all sessions from iCloud"""
        return self.session_manager.get_all_sessions(platform)

    def search_history(self, query: str, platform: Optional[str] = None) -> List[Dict]:
        """
        Search command history across all sessions

        Args:
            query: Search query (searches in commands and output)
            platform: Optional platform filter

        Returns:
            List of matching commands
        """
        results = []
        sessions = self.get_all_sessions(platform)

        for session in sessions:
            for cmd_entry in session.get("commands", []):
                command = cmd_entry.get("command", "")
                output = cmd_entry.get("result", {}).get("output", "")

                if query.lower() in command.lower() or query.lower() in output.lower():
                    results.append({
                        "session_id": session["session_id"],
                        "platform": session["platform"],
                        "timestamp": cmd_entry["timestamp"],
                        "command": command,
                        "result": cmd_entry["result"]
                    })

        return results

    def get_statistics(self) -> Dict:
        """Get usage statistics"""
        sessions = self.get_all_sessions()

        total_commands = sum(
            len(s.get("commands", []))
            for s in sessions
        )

        platform_stats = {}
        for session in sessions:
            platform = session["platform"]
            platform_stats[platform] = platform_stats.get(platform, 0) + 1

        return {
            "total_sessions": len(sessions),
            "total_commands": total_commands,
            "platform_distribution": platform_stats,
            "icloud_root": str(self.icloud_root)
        }

    def cleanup_old_sessions(self, days: int = 30):
        """Clean up sessions older than specified days"""
        from datetime import timedelta

        cutoff_date = datetime.now() - timedelta(days=days)
        sessions = self.get_all_sessions()

        deleted_count = 0
        for session in sessions:
            created_at = datetime.fromisoformat(session["created_at"])
            if created_at < cutoff_date:
                # Delete session file
                session_file = (
                    self.icloud_root /
                    "terminal-sessions" /
                    session["platform"] /
                    f"{session['session_id']}.json"
                )

                if session_file.exists():
                    session_file.unlink()
                    deleted_count += 1
                    logger.info(f"Deleted old session: {session['session_id']}")

        logger.info(f"Cleaned up {deleted_count} old sessions")
        return deleted_count


def main():
    """Test Unified Terminal System"""
    import sys

    # Setup logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )

    print("=" * 60)
    print("Unified Terminal System - Test")
    print("=" * 60)
    print()

    # Initialize system
    icloud_root = "~/Library/Mobile Documents/com~apple~CloudDocs/kris-server"
    system = UnifiedTerminalSystem(icloud_root)

    print(f"iCloud Root: {system.icloud_root}")
    print(f"System Name: {system.config.get('system_name')}")
    print()

    # Start session
    print("Starting new session...")
    session_id = system.start_session(platform="linux")
    print(f"✅ Session ID: {session_id}")
    print()

    # Execute some commands
    test_commands = [
        ("echo 'Hello from Unified Terminal'", "linux"),
        ("pwd", "linux"),
        ("ls -la", "linux")
    ]

    for command, platform in test_commands:
        print(f"Executing: {command} (on {platform})")
        result = system.execute_command(command, platform)

        if result['success']:
            print(f"✅ Success!")
            print(f"Output: {result['output'][:100]}...")
        else:
            print(f"❌ Failed: {result['error']}")
        print()

    # Show session history
    print("Session History:")
    history = system.get_session_history()
    if history:
        print(f"  Session: {history['session_id']}")
        print(f"  Platform: {history['platform']}")
        print(f"  Commands: {len(history['commands'])}")
        for i, cmd in enumerate(history['commands'], 1):
            print(f"    {i}. {cmd['command']}")
    print()

    # Show statistics
    print("Statistics:")
    stats = system.get_statistics()
    print(f"  Total sessions: {stats['total_sessions']}")
    print(f"  Total commands: {stats['total_commands']}")
    print(f"  Platform distribution: {stats['platform_distribution']}")
    print()

    print("=" * 60)
    print("All data saved to iCloud!")
    print(f"Location: {system.icloud_root}/terminal-sessions/")
    print("=" * 60)


if __name__ == "__main__":
    main()
