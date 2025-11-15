#!/usr/bin/env python3
"""
WanMap テストデータ作成スクリプト
箱根周辺の実在する散歩ルートを3件作成し、それぞれに写真を追加します。
"""

import requests
import json
from datetime import datetime, timedelta
import random

# Supabase設定
SUPABASE_URL = "https://jkpenklhrlbctebkpvax.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImprcGVua2xocmxiY3RlYmtwdmF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MjcwMDUsImV4cCI6MjA3ODUwMzAwNX0.7Blk7ZgGMBN1orsovHgaTON7IDVDJ0Er_QGru8ZMZz8"

headers = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

# 箱根周辺の実際のGPS座標（DogHub周辺）
# 箱根町の座標: 35.2323, 139.1070
HAKONE_BASE_LAT = 35.2323
HAKONE_BASE_LNG = 139.1070

def get_test_user():
    """既存のユーザーを取得、なければ作成"""
    # まず既存ユーザーを確認
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/profiles",
        headers=headers,
        params={"select": "id,display_name", "limit": "1"}
    )
    
    if response.status_code == 200 and response.json():
        user = response.json()[0]
        print(f"✅ 既存ユーザーを使用: {user['display_name']} (ID: {user['id']})")
        return user['id']
    
    print("❌ ユーザーが見つかりません。Supabaseでユーザーを作成してください。")
    return None

def generate_route_points(start_lat, start_lng, num_points=50):
    """ランダムな散歩ルートのGPSポイントを生成"""
    points = []
    current_lat = start_lat
    current_lng = start_lng
    
    for i in range(num_points):
        # ランダムに少しずつ移動（約5-10メートル）
        delta_lat = random.uniform(-0.0001, 0.0001)
        delta_lng = random.uniform(-0.0001, 0.0001)
        
        current_lat += delta_lat
        current_lng += delta_lng
        
        points.append({
            "latitude": current_lat,
            "longitude": current_lng,
            "altitude": random.uniform(100, 150),  # 箱根の標高
            "timestamp": (datetime.now() - timedelta(minutes=num_points - i)).isoformat(),
            "sequence_number": i
        })
    
    return points

def create_route(user_id, title, description, distance, duration, start_lat, start_lng):
    """ルートを作成"""
    route_data = {
        "user_id": user_id,
        "title": title,
        "description": description,
        "distance": distance,
        "duration": duration,
        "is_public": True,
        "created_at": (datetime.now() - timedelta(days=random.randint(1, 30))).isoformat()
    }
    
    response = requests.post(
        f"{SUPABASE_URL}/rest/v1/routes",
        headers=headers,
        json=route_data
    )
    
    if response.status_code in [200, 201]:
        route = response.json()[0]
        route_id = route['id']
        print(f"✅ ルート作成成功: {title} (ID: {route_id})")
        
        # GPSポイントを作成
        num_points = int(duration / 60 * 10)  # 1分あたり10ポイント
        points = generate_route_points(start_lat, start_lng, num_points)
        
        # route_idを追加
        for point in points:
            point['route_id'] = route_id
        
        # ポイントをバッチ挿入
        point_response = requests.post(
            f"{SUPABASE_URL}/rest/v1/route_points",
            headers=headers,
            json=points
        )
        
        if point_response.status_code in [200, 201]:
            print(f"  ✅ GPSポイント {len(points)}件 追加完了")
        else:
            print(f"  ❌ GPSポイント追加失敗: {point_response.status_code} - {point_response.text}")
        
        return route_id
    else:
        print(f"❌ ルート作成失敗: {response.status_code} - {response.text}")
        return None

def add_photos_to_route(route_id, user_id, num_photos=3):
    """ルートに写真を追加（Unsplash APIからダミー画像を使用）"""
    # Unsplashのランダム犬画像URL
    photo_urls = [
        "https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=800",  # Golden Retriever
        "https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=800",  # Shiba Inu
        "https://images.unsplash.com/photo-1552053831-71594a27632d?w=800",  # Husky
        "https://images.unsplash.com/photo-1517849845537-4d257902454a?w=800",  # Dog in nature
        "https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=800",  # Happy dog
        "https://images.unsplash.com/photo-1530281700549-e82e7bf110d6?w=800",  # Dog portrait
    ]
    
    for i in range(num_photos):
        photo_url = random.choice(photo_urls)
        
        photo_data = {
            "route_id": route_id,
            "user_id": user_id,
            "storage_path": f"test/{route_id}/{i}.jpg",
            "public_url": photo_url,
            "caption": f"散歩中の素敵な一枚 #{i+1}",
            "created_at": datetime.now().isoformat()
        }
        
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/route_photos",
            headers=headers,
            json=photo_data
        )
        
        if response.status_code in [200, 201]:
            print(f"  ✅ 写真 {i+1}/{num_photos} 追加完了")
        else:
            print(f"  ❌ 写真追加失敗: {response.status_code} - {response.text}")

def main():
    print("=" * 60)
    print("🐕 WanMap テストデータ作成スクリプト")
    print("=" * 60)
    print()
    
    # ユーザー確認
    user_id = get_test_user()
    if not user_id:
        print("\n❌ ユーザーが見つかりません。まずSupabaseでユーザーを作成してください。")
        return
    
    print()
    print("-" * 60)
    print("📍 テストルート作成中...")
    print("-" * 60)
    print()
    
    # ルート1: 芦ノ湖畔散歩コース
    route_id_1 = create_route(
        user_id=user_id,
        title="芦ノ湖畔の朝散歩コース",
        description="芦ノ湖の美しい景色を眺めながらの爽やかな朝の散歩。愛犬も大喜びでした！",
        distance=2500,  # 2.5km
        duration=1800,  # 30分
        start_lat=35.2050,
        start_lng=139.0250
    )
    
    if route_id_1:
        add_photos_to_route(route_id_1, user_id, 3)
    
    print()
    
    # ルート2: 箱根旧街道コース
    route_id_2 = create_route(
        user_id=user_id,
        title="箱根旧街道 歴史散歩",
        description="石畳の旧街道を歩く歴史ロマン溢れる散歩コース。杉並木が素晴らしかったです。",
        distance=3200,  # 3.2km
        duration=2400,  # 40分
        start_lat=35.2150,
        start_lng=139.0320
    )
    
    if route_id_2:
        add_photos_to_route(route_id_2, user_id, 2)
    
    print()
    
    # ルート3: 仙石原すすき草原コース
    route_id_3 = create_route(
        user_id=user_id,
        title="仙石原すすき草原 夕焼けコース",
        description="黄金色に輝くすすき草原での夕方散歩。愛犬も走り回って楽しそうでした！",
        distance=1800,  # 1.8km
        duration=1500,  # 25分
        start_lat=35.2400,
        start_lng=139.0150
    )
    
    if route_id_3:
        add_photos_to_route(route_id_3, user_id, 3)
    
    print()
    print("=" * 60)
    print("✅ テストデータ作成完了！")
    print("=" * 60)
    print()
    print("📱 iPhoneアプリで以下を確認してください：")
    print("  1. ホーム画面でルート一覧を表示")
    print("  2. 各ルートをタップして詳細表示")
    print("  3. 地図上にルートが描画されることを確認")
    print("  4. 写真ギャラリーが表示されることを確認")
    print()

if __name__ == "__main__":
    main()
