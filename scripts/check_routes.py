#!/usr/bin/env python3
"""
各エリアのルート数を確認
"""

import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv('/home/user/wanmap_v2/.env')

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# エリアID
areas = {
    '箱根': 'a1111111-1111-1111-1111-111111111111',
    '横浜': 'a2222222-2222-2222-2222-222222222222',
    '鎌倉': 'a3333333-3333-3333-3333-333333333333',
}

print("=" * 60)
print("📊 各エリアのルート数")
print("=" * 60)

for area_name, area_id in areas.items():
    result = supabase.table('official_routes').select('id', count='exact').eq('area_id', area_id).execute()
    count = result.count if hasattr(result, 'count') else len(result.data)
    print(f"{area_name}: {count}本")

print("=" * 60)
