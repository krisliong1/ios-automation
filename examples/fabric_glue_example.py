#!/usr/bin/env python3
"""
Fabric Glue Usage Example - 胶水编程示例

展示如何使用 Fabric (14K+ stars GitHub library) 进行跨平台命令执行
只需要 ~10 行代码就能实现完整的远程命令执行 + iCloud 同步
"""

import sys
from pathlib import Path

# 添加 src 到路径
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from fabric_glue import FabricGlue, quick_execute


def example_1_basic_usage():
    """示例 1: 基础用法"""
    print("=" * 70)
    print("示例 1: 基础用法 - 使用 Fabric 执行远程命令")
    print("=" * 70)
    print()

    # 创建 Fabric Glue 实例
    glue = FabricGlue(
        icloud_root="~/Library/Mobile Documents/com~apple~CloudDocs/kris-server"
    )

    # 添加主机配置
    # 注意：请修改为你的实际服务器信息
    print("添加主机配置...")
    glue.add_host(
        name="my-linux-server",
        hostname="192.168.1.100",  # 修改为你的服务器 IP
        username="user",            # 修改为你的用户名
        key_file="~/.ssh/id_rsa"    # 修改为你的 SSH 密钥路径
    )

    # 执行命令
    print("\n执行命令: ls -la")
    result = glue.execute("my-linux-server", "ls -la")

    print(f"\n结果:")
    print(f"  ✅ 成功: {result['success']}")
    print(f"  📝 输出: {result['output'][:200]}...")
    print(f"  💾 已自动保存到 iCloud")
    print()


def example_2_multiple_hosts():
    """示例 2: 管理多个主机"""
    print("=" * 70)
    print("示例 2: 管理多个主机")
    print("=" * 70)
    print()

    glue = FabricGlue(
        icloud_root="~/Library/Mobile Documents/com~apple~CloudDocs/kris-server"
    )

    # 添加多个主机
    hosts = [
        {
            "name": "linux-server",
            "hostname": "192.168.1.100",
            "username": "user",
            "key_file": "~/.ssh/id_rsa"
        },
        {
            "name": "mac-mini",
            "hostname": "192.168.1.101",
            "username": "user",
            "key_file": "~/.ssh/id_rsa"
        }
    ]

    for host in hosts:
        glue.add_host(**host)

    # 在所有主机上执行相同命令
    print("在所有主机上执行: uptime")
    results = glue.execute_on_all("uptime")

    for host_name, result in results.items():
        print(f"\n{host_name}:")
        print(f"  输出: {result['output']}")


def example_3_with_config_file():
    """示例 3: 使用配置文件"""
    print("=" * 70)
    print("示例 3: 使用配置文件")
    print("=" * 70)
    print()

    # 配置文件会自动从 iCloud 加载
    # 位置: ~/Library/Mobile Documents/com~apple~CloudDocs/kris-server/shared-config/fabric-hosts.json

    glue = FabricGlue(
        icloud_root="~/Library/Mobile Documents/com~apple~CloudDocs/kris-server"
    )

    # 如果配置文件存在，主机会自动加载
    # 如果不存在，可以手动添加主机后保存配置

    # 添加一个主机
    glue.add_host(
        name="production-server",
        hostname="prod.example.com",
        username="deploy",
        key_file="~/.ssh/prod_key"
    )

    # 保存配置到 iCloud（下次自动加载）
    glue.save_config()
    print("✅ 配置已保存到 iCloud")
    print("   下次启动时会自动加载这些主机配置")


def example_4_command_history():
    """示例 4: 查看命令历史"""
    print("=" * 70)
    print("示例 4: 查看命令历史")
    print("=" * 70)
    print()

    glue = FabricGlue(
        icloud_root="~/Library/Mobile Documents/com~apple~CloudDocs/kris-server"
    )

    # 获取今天的历史
    history = glue.get_history()

    print(f"今天执行了 {len(history)} 条命令:")
    for entry in history[:5]:  # 显示最近 5 条
        print(f"  [{entry['timestamp']}] {entry['command']}")

    # 搜索历史
    search_results = glue.search_history("ls")
    print(f"\n包含 'ls' 的命令: {len(search_results)} 条")


def example_5_one_liner():
    """示例 5: 一行代码执行命令"""
    print("=" * 70)
    print("示例 5: 一行代码执行命令")
    print("=" * 70)
    print()

    # 使用 quick_execute 快捷函数
    # 注意：需要先配置主机（使用 example_3）

    result = quick_execute("my-server", "echo 'Hello from Fabric Glue!'")
    print(f"结果: {result['output']}")


def show_menu():
    """显示菜单"""
    print()
    print("=" * 70)
    print("Fabric Glue Examples - 胶水编程示例")
    print("=" * 70)
    print()
    print("请选择一个示例运行:")
    print()
    print("1. 基础用法 - 执行远程命令")
    print("2. 管理多个主机")
    print("3. 使用配置文件")
    print("4. 查看命令历史")
    print("5. 一行代码执行命令")
    print()
    print("0. 退出")
    print()


if __name__ == "__main__":
    print()
    print("⚠️  注意：运行示例前，请修改以下内容：")
    print("   1. hostname - 修改为你的服务器 IP/域名")
    print("   2. username - 修改为你的 SSH 用户名")
    print("   3. key_file - 修改为你的 SSH 密钥路径")
    print()

    while True:
        show_menu()

        choice = input("选择 (0-5): ").strip()

        if choice == "0":
            print("\n👋 退出")
            break
        elif choice == "1":
            example_1_basic_usage()
        elif choice == "2":
            example_2_multiple_hosts()
        elif choice == "3":
            example_3_with_config_file()
        elif choice == "4":
            example_4_command_history()
        elif choice == "5":
            example_5_one_liner()
        else:
            print("❌ 无效选择")

        input("\n按 Enter 继续...")
