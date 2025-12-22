#!/usr/bin/env python3
"""
WanWalk 既存ルートデータをCSV出力するスクリプト

使い方:
  python export_routes_to_csv.py output_routes.csv

前提条件:
  - Supabaseの環境変数が設定されていること
  - または、.env ファイルに SUPABASE_URL と SUPABASE_KEY が設定されていること
"""

import csv
import sys
import os
import json
from datetime import datetime

# Supabase接続用（実際の環境では適切に設定してください）
SUPABASE_URL = os.getenv('SUPABASE_URL', '')
SUPABASE_KEY = os.getenv('SUPABASE_KEY', '')

def export_routes_to_csv(output_csv_path):
    """
    既存のルートデータをCSVに出力
    
    注意: このスクリプトはSupabase接続が必要です。
    実際には、Supabase SQL Editorで以下のクエリを実行し、
    結果をCSV形式でダウンロードしてください。
    """
    
    print("=" * 60)
    print("WanWalk ルートデータCSV出力ガイド")
    print("=" * 60)
    print()
    print("このスクリプトは、Supabase SQL Editorで以下のクエリを実行し、")
    print("結果をCSVダウンロードする手順を案内します。")
    print()
    print("【ステップ1】Supabase SQL Editorにアクセス")
    print("  https://supabase.com/dashboard/project/YOUR_PROJECT_ID/sql")
    print()
    print("【ステップ2】以下のSQLクエリを実行")
    print()
    
    sql_query = """
-- 既存ルートデータを取得（CSV出力用）
SELECT 
  r.id AS ルートID,
  r.title AS ルート名,
  a.name AS エリア,
  a.prefecture AS 都道府県,
  r.description AS ルート説明,
  r.distance_km AS 距離km,
  r.estimated_duration_minutes AS 所要時間分,
  r.difficulty AS 難易度,
  r.elevation_gain_m AS 標高差m,
  
  -- pet_infoからJSON展開
  r.pet_info->>'parking' AS 駐車場情報,
  r.pet_info->>'surface' AS 路面状況,
  r.pet_info->>'restroom' AS トイレ情報,
  r.pet_info->>'water_station' AS 水飲み場情報,
  r.pet_info->>'pet_facilities' AS ペット関連施設,
  r.pet_info->>'others' AS その他備考,
  
  -- 座標情報
  CASE 
    WHEN r.start_location IS NOT NULL THEN 
      ST_Y(r.start_location::geometry) || ',' || ST_X(r.start_location::geometry)
    ELSE NULL
  END AS 開始地点座標,
  
  CASE 
    WHEN r.end_location IS NOT NULL THEN 
      ST_Y(r.end_location::geometry) || ',' || ST_X(r.end_location::geometry)
    ELSE NULL
  END AS 終了地点座標,
  
  -- route_line存在チェック
  CASE WHEN r.route_line IS NOT NULL THEN 'あり' ELSE 'なし' END AS ルート軌跡,
  
  -- サムネイル・ギャラリー
  r.thumbnail_url AS サムネイルURL,
  CASE 
    WHEN array_length(r.gallery_images, 1) > 0 THEN r.gallery_images[1]
    ELSE NULL
  END AS 写真URL1,
  CASE 
    WHEN array_length(r.gallery_images, 1) > 1 THEN r.gallery_images[2]
    ELSE NULL
  END AS 写真URL2,
  CASE 
    WHEN array_length(r.gallery_images, 1) > 2 THEN r.gallery_images[3]
    ELSE NULL
  END AS 写真URL3,
  
  -- 統計情報
  r.total_pins AS ピン数,
  r.total_walks AS 散歩回数,
  
  -- タイムスタンプ
  r.created_at AS 作成日時,
  r.updated_at AS 更新日時

FROM official_routes r
LEFT JOIN areas a ON r.area_id = a.id
ORDER BY a.name, r.title;
"""
    
    print(sql_query)
    print()
    print("【ステップ3】結果をCSVダウンロード")
    print("  1. クエリ実行後、結果テーブルの右上「Download CSV」ボタンをクリック")
    print("  2. ダウンロードしたCSVを開く")
    print()
    print("【ステップ4】CSVデータ精査")
    print("  以下の項目を確認してください：")
    print("  - ✅ エリア名が正しいか（箱根の場合は5サブエリアのいずれか）")
    print("  - ✅ 距離・所要時間が適切か（3.0km/h基準）")
    print("  - ✅ pet_info情報が充実しているか")
    print("  - ✅ 座標データが入っているか")
    print("  - ✅ ルート軌跡（route_line）が入っているか")
    print("  - ✅ サムネイル・写真URLが設定されているか")
    print()
    print("【ステップ5】データ修正")
    print("  問題があるルートは、以下の方法で修正してください：")
    print("  1. CSVで修正後、csv_to_sql.py で再投入")
    print("  2. または、Supabase SQL EditorでUPDATE文を実行")
    print()
    print("=" * 60)
    print()
    
    # SQLクエリをファイルに保存
    sql_file = 'scripts/export_routes_query.sql'
    with open(sql_file, 'w', encoding='utf-8') as f:
        f.write("-- ========================================\n")
        f.write("-- WanWalk 既存ルートデータ取得クエリ\n")
        f.write(f"-- 生成日時: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write("-- ========================================\n\n")
        f.write(sql_query)
    
    print(f"✅ SQLクエリを保存しました: {sql_file}")
    print()
    print("次のステップ:")
    print(f"1. Supabase SQL Editorを開く")
    print(f"2. {sql_file} の内容をコピー&ペーストして実行")
    print(f"3. 結果をCSVダウンロード")
    print(f"4. ダウンロードしたCSVを精査・修正")

def main():
    if len(sys.argv) < 2:
        output_file = "existing_routes.csv"
        print(f"出力ファイル名が指定されていないため、デフォルトを使用します: {output_file}")
    else:
        output_file = sys.argv[1]
    
    export_routes_to_csv(output_file)

if __name__ == '__main__':
    main()
