"""
iCloud Sync Engine
Handles synchronization between local files and iCloud Drive
"""

import os
import json
import shutil
import hashlib
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional
import logging

logger = logging.getLogger(__name__)


class iCloudSyncEngine:
    """iCloud Drive synchronization engine"""

    def __init__(self, icloud_root: str):
        """
        Initialize iCloud sync engine

        Args:
            icloud_root: Path to iCloud Drive root
                         e.g., ~/Library/Mobile Documents/com~apple~CloudDocs/kris-server
        """
        self.icloud_root = Path(os.path.expanduser(icloud_root))
        self.config_path = self.icloud_root / "shared-config" / "icloud-sync.json"
        self.status_path = self.icloud_root / "sync-status" / "last-sync.json"

        self.ensure_icloud_structure()
        self.config = self.load_sync_config()

    def ensure_icloud_structure(self):
        """Create iCloud directory structure if it doesn't exist"""
        directories = [
            "ios-automation",
            "ai-systems/ai-manager",
            "ai-systems/ai-fixer",
            "ai-systems/claude-router",
            "ai-systems/models",
            "terminal-sessions/macos",
            "terminal-sessions/linux",
            "terminal-sessions/ios",
            "terminal-sessions/windows",
            "automation-logs/execution-history",
            "automation-logs/error-logs",
            "automation-logs/performance",
            "shared-config",
            "sync-status",
            "sync-status/conflicts"
        ]

        for directory in directories:
            dir_path = self.icloud_root / directory
            dir_path.mkdir(parents=True, exist_ok=True)
            logger.info(f"Ensured directory exists: {dir_path}")

    def load_sync_config(self) -> Dict:
        """Load synchronization configuration"""
        if self.config_path.exists():
            with open(self.config_path, 'r') as f:
                return json.load(f)
        else:
            # Default configuration
            default_config = {
                "sync_rules": {
                    "Sources/": {
                        "priority": "high",
                        "bidirectional": True,
                        "conflict_resolution": "manual"
                    },
                    "src/": {
                        "priority": "high",
                        "bidirectional": True,
                        "conflict_resolution": "manual"
                    },
                    "data/": {
                        "priority": "medium",
                        "bidirectional": True,
                        "conflict_resolution": "latest"
                    }
                },
                "exclude": [
                    ".git/",
                    "__pycache__/",
                    ".DS_Store",
                    "*.pyc",
                    "build/",
                    ".build/"
                ]
            }

            # Save default config
            self.config_path.parent.mkdir(parents=True, exist_ok=True)
            with open(self.config_path, 'w') as f:
                json.dump(default_config, f, indent=2)

            return default_config

    def sync_to_icloud(self, source_path: str, relative_path: str = "ios-automation"):
        """
        Sync local files to iCloud

        Args:
            source_path: Local source directory
            relative_path: Relative path in iCloud (default: ios-automation)
        """
        source = Path(source_path)
        dest = self.icloud_root / relative_path

        if not source.exists():
            logger.error(f"Source path does not exist: {source}")
            return False

        logger.info(f"Syncing {source} -> {dest}")

        try:
            # Copy files
            if source.is_file():
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, dest)
                logger.info(f"Synced file: {source.name}")
            else:
                self._sync_directory(source, dest)

            # Update sync status
            self.update_sync_status(relative_path)

            return True

        except Exception as e:
            logger.error(f"Sync failed: {e}")
            return False

    def _sync_directory(self, source: Path, dest: Path):
        """Recursively sync directory"""
        dest.mkdir(parents=True, exist_ok=True)

        for item in source.iterdir():
            # Check if excluded
            if self._is_excluded(item.name):
                continue

            src_item = source / item.name
            dest_item = dest / item.name

            if src_item.is_file():
                # Check if file needs update
                if self._needs_update(src_item, dest_item):
                    shutil.copy2(src_item, dest_item)
                    logger.debug(f"Synced: {item.name}")
            elif src_item.is_dir():
                self._sync_directory(src_item, dest_item)

    def _is_excluded(self, name: str) -> bool:
        """Check if file/directory should be excluded"""
        exclude_patterns = self.config.get("exclude", [])

        for pattern in exclude_patterns:
            if pattern.endswith('/'):
                # Directory pattern
                if name == pattern.rstrip('/'):
                    return True
            elif '*' in pattern:
                # Wildcard pattern
                if pattern.startswith('*.'):
                    ext = pattern[1:]
                    if name.endswith(ext):
                        return True
            else:
                # Exact match
                if name == pattern:
                    return True

        return False

    def _needs_update(self, source: Path, dest: Path) -> bool:
        """Check if destination needs to be updated"""
        if not dest.exists():
            return True

        # Compare modification times
        src_mtime = source.stat().st_mtime
        dest_mtime = dest.stat().st_mtime

        return src_mtime > dest_mtime

    def sync_from_icloud(self, relative_path: str, dest_path: str):
        """
        Sync from iCloud to local

        Args:
            relative_path: Relative path in iCloud
            dest_path: Local destination directory
        """
        source = self.icloud_root / relative_path
        dest = Path(dest_path)

        if not source.exists():
            logger.error(f"iCloud path does not exist: {source}")
            return False

        logger.info(f"Syncing {source} -> {dest}")

        try:
            if source.is_file():
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, dest)
            else:
                self._sync_directory(source, dest)

            return True

        except Exception as e:
            logger.error(f"Sync from iCloud failed: {e}")
            return False

    def update_sync_status(self, path: str):
        """Update synchronization status"""
        status = {
            "path": path,
            "last_sync": datetime.now().isoformat(),
            "status": "success"
        }

        self.status_path.parent.mkdir(parents=True, exist_ok=True)

        # Load existing status
        if self.status_path.exists():
            with open(self.status_path, 'r') as f:
                all_status = json.load(f)
        else:
            all_status = {"syncs": []}

        # Add new status
        all_status["syncs"].append(status)

        # Keep only last 100 syncs
        all_status["syncs"] = all_status["syncs"][-100:]

        # Save status
        with open(self.status_path, 'w') as f:
            json.dump(all_status, f, indent=2)

        logger.info(f"Updated sync status for: {path}")

    def get_sync_status(self) -> Dict:
        """Get current sync status"""
        if self.status_path.exists():
            with open(self.status_path, 'r') as f:
                return json.load(f)
        return {"syncs": []}

    def calculate_file_hash(self, file_path: Path) -> str:
        """Calculate MD5 hash of a file"""
        md5 = hashlib.md5()
        with open(file_path, 'rb') as f:
            for chunk in iter(lambda: f.read(4096), b""):
                md5.update(chunk)
        return md5.hexdigest()

    def detect_conflicts(self, local_path: str, icloud_relative_path: str) -> List[Dict]:
        """Detect synchronization conflicts"""
        conflicts = []
        local = Path(local_path)
        icloud = self.icloud_root / icloud_relative_path

        if not local.exists() or not icloud.exists():
            return conflicts

        # Check all files
        for local_file in local.rglob('*'):
            if local_file.is_file() and not self._is_excluded(local_file.name):
                relative = local_file.relative_to(local)
                icloud_file = icloud / relative

                if icloud_file.exists():
                    # Both files exist, check for conflicts
                    local_hash = self.calculate_file_hash(local_file)
                    icloud_hash = self.calculate_file_hash(icloud_file)

                    if local_hash != icloud_hash:
                        # Hashes differ, potential conflict
                        conflict = {
                            "file": str(relative),
                            "local_path": str(local_file),
                            "icloud_path": str(icloud_file),
                            "local_modified": datetime.fromtimestamp(
                                local_file.stat().st_mtime
                            ).isoformat(),
                            "icloud_modified": datetime.fromtimestamp(
                                icloud_file.stat().st_mtime
                            ).isoformat(),
                            "local_hash": local_hash,
                            "icloud_hash": icloud_hash
                        }
                        conflicts.append(conflict)

        return conflicts

    def resolve_conflict(self, conflict: Dict, resolution: str = "keep_both"):
        """
        Resolve a synchronization conflict

        Args:
            conflict: Conflict dictionary from detect_conflicts()
            resolution: "local", "icloud", "keep_both", or "manual"
        """
        local_file = Path(conflict["local_path"])
        icloud_file = Path(conflict["icloud_path"])

        if resolution == "local":
            # Use local version
            shutil.copy2(local_file, icloud_file)
            logger.info(f"Resolved conflict (kept local): {conflict['file']}")

        elif resolution == "icloud":
            # Use iCloud version
            shutil.copy2(icloud_file, local_file)
            logger.info(f"Resolved conflict (kept iCloud): {conflict['file']}")

        elif resolution == "keep_both":
            # Keep both versions
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            local_backup = local_file.parent / f"{local_file.stem}_local_{timestamp}{local_file.suffix}"
            shutil.copy2(local_file, local_backup)
            shutil.copy2(icloud_file, local_file)
            logger.info(f"Resolved conflict (kept both): {conflict['file']}")

        elif resolution == "manual":
            # Save conflict for manual resolution
            conflict_dir = self.icloud_root / "sync-status" / "conflicts"
            conflict_dir.mkdir(parents=True, exist_ok=True)

            conflict_file = conflict_dir / f"{conflict['file'].replace('/', '_')}.json"
            with open(conflict_file, 'w') as f:
                json.dump(conflict, f, indent=2)

            logger.info(f"Saved conflict for manual resolution: {conflict_file}")

    def auto_sync(self, local_path: str, icloud_relative_path: str = "ios-automation"):
        """
        Automatic bidirectional synchronization

        Args:
            local_path: Local directory path
            icloud_relative_path: Relative path in iCloud
        """
        logger.info("Starting auto-sync...")

        # Detect conflicts first
        conflicts = self.detect_conflicts(local_path, icloud_relative_path)

        if conflicts:
            logger.warning(f"Found {len(conflicts)} conflicts")
            for conflict in conflicts:
                self.resolve_conflict(conflict, resolution="keep_both")

        # Sync to iCloud
        self.sync_to_icloud(local_path, icloud_relative_path)

        # Sync from iCloud (for new files added elsewhere)
        # This would pull down files that were added to iCloud from other devices

        logger.info("Auto-sync completed")


def main():
    """Test iCloud sync engine"""
    import sys

    # Setup logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )

    # Initialize engine
    icloud_root = "~/Library/Mobile Documents/com~apple~CloudDocs/kris-server"
    engine = iCloudSyncEngine(icloud_root)

    # Get current directory
    current_dir = Path.cwd()

    print("=" * 60)
    print("iCloud Sync Engine - Test")
    print("=" * 60)
    print(f"iCloud Root: {engine.icloud_root}")
    print(f"Local Path: {current_dir}")
    print()

    # Sync to iCloud
    print("Syncing to iCloud...")
    success = engine.sync_to_icloud(str(current_dir), "ios-automation")

    if success:
        print("✅ Sync to iCloud successful!")
    else:
        print("❌ Sync to iCloud failed!")

    # Show sync status
    print("\nSync Status:")
    status = engine.get_sync_status()
    if status.get("syncs"):
        last_sync = status["syncs"][-1]
        print(f"  Last sync: {last_sync['last_sync']}")
        print(f"  Path: {last_sync['path']}")
        print(f"  Status: {last_sync['status']}")
    else:
        print("  No sync history")


if __name__ == "__main__":
    main()
