#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# ============================================================
# 脚本名称：card_generator.py
# 功能描述：卡牌生成器工具，用于批量生成卡牌场景文件
# 作者：Godot开发团队
# 创建日期：2026-01-29
# 依赖：godot_parser (pip install godot_parser)
# ============================================================

import json
import sys
from pathlib import Path
from typing import Dict, Any

try:
    from godot_parser import GDScene, Node, Resource as GDResource
except ImportError:
    print("错误：需要安装 godot_parser")
    print("请运行: pip install godot_parser")
    sys.exit(1)


class CardGenerator:
    """卡牌生成器"""
    
    def __init__(self, config_path: str, output_dir: str):
        """
        初始化卡牌生成器
        
        Args:
            config_path: 卡牌配置文件路径
            output_dir: 输出目录
        """
        self.config_path = Path(config_path)
        self.output_dir = Path(output_dir)
        self.card_data = {}
        
    def load_config(self) -> bool:
        """加载卡牌配置
        
        Returns:
            bool: 是否加载成功
        """
        if not self.config_path.exists():
            print(f"错误：配置文件不存在: {self.config_path}")
            return False
        
        try:
            with open(self.config_path, 'r', encoding='utf-8') as f:
                config = json.load(f)
                self.card_data = config.get('cards', {})
            print(f"成功加载配置: {len(self.card_data)} 张卡牌")
            return True
        except json.JSONDecodeError as e:
            print(f"错误：配置文件JSON解析失败: {e}")
            return False
        except Exception as e:
            print(f"错误：加载配置文件失败: {e}")
            return False
    
    def generate_card_scene(self, card_key: str, card_info: Dict[str, Any]) -> GDScene:
        """生成卡牌场景文件
        
        Args:
            card_key: 卡牌键值
            card_info: 卡牌信息字典
        
        Returns:
            GDScene: 卡牌场景对象
        """
        # 创建场景
        scene = GDScene()
        
        # 创建根节点
        root = Node("CardController")
        root.type = "Node2D"
        scene.add_child(root)
        
        # 添加属性
        root.set_property("script", "res://scripts/controllers/CardController.gd")
        root.set_property("card_id", card_info.get("id", 0))
        root.set_property("card_type", card_info.get("type", "scenery"))
        root.set_property("card_tier", card_info.get("tier", 1))
        
        # 添加背景精灵
        background = Node("Background")
        background.type = "ColorRect"
        background.set_property("color", "rgba(0.8, 0.8, 0.8, 1.0)")
        background.set_property("offset_left", -50.0)
        background.set_property("offset_top", -70.0)
        background.set_property("offset_right", 50.0)
        background.set_property("offset_bottom", 70.0)
        root.add_child(background)
        
        # 添加卡牌图标
        icon_sprite = Node("IconSprite")
        icon_sprite.type = "Sprite2D"
        icon_sprite.set_property("texture", f"res://{card_info.get('icon_path', '')}")
        root.add_child(icon_sprite)
        
        # 添加名称标签
        name_label = Node("NameLabel")
        name_label.type = "Label"
        name_label.set_property("text", card_info.get("name", ""))
        name_label.set_property("position", "Vector2(0, -40)")
        name_label.set_property("horizontal_alignment", 1)  # Center
        root.add_child(name_label)
        
        # 添加描述标签
        desc_label = Node("DescriptionLabel")
        desc_label.type = "RichTextLabel"
        desc_label.set_property("bbcode_enabled", True)
        desc_label.set_property("text", card_info.get("description", ""))
        desc_label.set_property("position", "Vector2(-40, 20)")
        desc_label.set_property("size", "Vector2(80, 40)")
        root.add_child(desc_label)
        
        # 添加等级标签
        tier_label = Node("TierLabel")
        tier_label.type = "Label"
        tier_label.set_property("text", f"T{card_info.get('tier', 1)}")
        tier_label.set_property("position", "Vector2(35, -55)")
        root.add_child(tier_label)
        
        return scene
    
    def generate_all_cards(self) -> int:
        """生成所有卡牌场景文件
        
        Returns:
            int: 成功生成的卡牌数量
        """
        if not self.card_data:
            print("错误：没有卡牌数据")
            return 0
        
        # 创建输出目录
        output_dir = self.output_dir / "scenes" / "cards"
        output_dir.mkdir(parents=True, exist_ok=True)
        
        success_count = 0
        
        for card_key, card_info in self.card_data.items():
            try:
                scene = self.generate_card_scene(card_key, card_info)
                output_path = output_dir / f"{card_info.get('name', 'card')}.tscn"
                scene.write(str(output_path))
                print(f"✓ 生成卡牌: {card_info.get('name', card_key)}")
                success_count += 1
            except Exception as e:
                print(f"✗ 生成卡牌失败: {card_info.get('name', card_key)} - {e}")
        
        return success_count
    
    def update_card_database(self) -> bool:
        """更新卡牌数据库配置文件，添加场景路径
        
        Returns:
            bool: 是否更新成功
        """
        if not self.card_data:
            return False
        
        try:
            for card_key in self.card_data:
                card_name = self.card_data[card_key].get('name', '')
                if card_name:
                    self.card_data[card_key]['scene_path'] = f"res://scenes/cards/{card_name}.tscn"
            
            # 保存更新后的配置
            with open(self.config_path, 'w', encoding='utf-8') as f:
                json.dump({
                    "version": "1.0",
                    "last_updated": "2026-01-29",
                    "cards": self.card_data
                }, f, indent=2, ensure_ascii=False)
            
            print(f"✓ 更新卡牌数据库配置: {self.config_path}")
            return True
        except Exception as e:
            print(f"✗ 更新卡牌数据库失败: {e}")
            return False


def main():
    """主函数"""
    if len(sys.argv) < 2:
        print("用法: python card_generator.py <project_root>")
        print("示例: python card_generator.py /path/to/project")
        sys.exit(1)
    
    project_root = Path(sys.argv[1])
    config_path = project_root / "config" / "card_database.json"
    output_dir = project_root
    
    # 创建生成器
    generator = CardGenerator(str(config_path), str(output_dir))
    
    # 加载配置
    if not generator.load_config():
        sys.exit(1)
    
    # 生成所有卡牌
    print("\n开始生成卡牌场景文件...")
    print("=" * 50)
    success_count = generator.generate_all_cards()
    print("=" * 50)
    print(f"\n成功生成 {success_count} 张卡牌")
    
    # 更新卡牌数据库
    if success_count > 0:
        print("\n更新卡牌数据库配置...")
        generator.update_card_database()
    
    print("\n完成！")


if __name__ == "__main__":
    main()
