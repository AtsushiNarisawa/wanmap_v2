/**
 * 計算したルートジオメトリをSupabaseに保存
 */

const https = require('https');
const fs = require('fs');

// Supabase設定
const SUPABASE_URL = 'jkpenklhrlbctebkpvax.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImprcGVua2xocmxiY3RlYmtwdmF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MjcwMDUsImV4cCI6MjA3ODUwMzAwNX0.7Blk7ZgGMBN1orsovHgaTON7IDVDJ0Er_QGru8ZMZz8';

const ROUTE_ID = '779d1816-0c24-4d91-b5b2-2fbfc3292024';

/**
 * Supabase PATCH リクエスト
 */
function updateSupabase(id, data) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(data);

    const options = {
      hostname: SUPABASE_URL,
      port: 443,
      path: `/rest/v1/official_routes?id=eq.${id}`,
      method: 'PATCH',
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          resolve(data);
        }
      });
    });

    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

async function main() {
  try {
    console.log('📍 ルートジオメトリファイルを読み込み中...\n');

    // ジオメトリファイルを読み込み
    const geometryFile = 'route_geometry_akarenga.json';
    if (!fs.existsSync(geometryFile)) {
      console.log(`❌ ファイルが見つかりません: ${geometryFile}`);
      console.log('💡 先に calculate_akarenga_geometry.js を実行してください');
      return;
    }

    const geometry = JSON.parse(fs.readFileSync(geometryFile, 'utf8'));
    console.log(`✅ ジオメトリ読み込み成功`);
    console.log(`📍 座標ポイント数: ${geometry.coordinates.length} points\n`);

    // WKT (Well-Known Text) 形式に変換
    const coordinates = geometry.coordinates
      .map(coord => `${coord[0]} ${coord[1]}`)
      .join(', ');
    
    const wktLineString = `SRID=4326;LINESTRING(${coordinates})`;

    console.log('💾 Supabaseに保存中...\n');
    console.log(`📝 WKT形式: ${wktLineString.substring(0, 100)}...\n`);

    const result = await updateSupabase(ROUTE_ID, {
      route_line: wktLineString
    });

    if (result && result.length > 0) {
      console.log('✅ 更新成功！');
      console.log(`📊 ルート: ${result[0].name}`);
      console.log(`📍 route_lineが更新されました\n`);
    } else {
      console.log('⚠️ 更新結果:', result);
    }

  } catch (error) {
    console.error('❌ エラー:', error.message);
  }
}

// 実行
main();
