import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/supabase_config.dart';

void main() async {
  // Flutterバインディングの初期化
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Supabaseの初期化
    await SupabaseConfig.initialize();
    print('✅ Supabase initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize Supabase: $e');
  }
  
  // アプリを起動
  runApp(
    const ProviderScope(
      child: WanMapApp(),
    ),
  );
}

/// WanMapアプリのメインウィジェット
class WanMapApp extends StatelessWidget {
  const WanMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WanMap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // メインカラー：落ち着いた青色
        primaryColor: const Color(0xFF4A90E2),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2),
          secondary: const Color(0xFF7ED321), // アクセントカラー：明るい緑
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        useMaterial3: true,
        
        // AppBarのテーマ
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4A90E2),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        
        // FloatingActionButtonのテーマ
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF7ED321),
          foregroundColor: Colors.white,
        ),
        
        // ボタンのテーマ
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A90E2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        
        // テキストフィールドのテーマ
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        
        // カードのテーマ
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

/// スプラッシュ画面
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // アニメーションの設定
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _animationController.forward();
    
    // 2秒後に次の画面へ遷移（仮の実装）
    Future.delayed(const Duration(seconds: 2), () {
      // TODO: 認証状態に応じて適切な画面に遷移
      // if (SupabaseConfig.isLoggedIn) {
      //   Navigator.of(context).pushReplacement(...HomeScreen);
      // } else {
      //   Navigator.of(context).pushReplacement(...LoginScreen);
      // }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A90E2),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // アイコン
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.pets,
                  size: 70,
                  color: Color(0xFF4A90E2),
                ),
              ),
              const SizedBox(height: 30),
              
              // アプリ名
              const Text(
                'WanMap',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              
              // サブタイトル
              const Text(
                '愛犬の散歩ルート共有アプリ',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 50),
              
              // ローディングインジケーター
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
