import 'package:flutter/material.dart';

/// リトライ機能付きの非同期データ表示ウィジェット
class RetryableAsyncWidget<T> extends StatefulWidget {
  final Future<T> Function() futureBuilder;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? loadingWidget;
  final Widget Function(BuildContext context, dynamic error)? errorBuilder;
  final int maxRetries;

  const RetryableAsyncWidget({
    super.key,
    required this.futureBuilder,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
    this.maxRetries = 3,
  });

  @override
  State<RetryableAsyncWidget<T>> createState() =>
      _RetryableAsyncWidgetState<T>();
}

class _RetryableAsyncWidgetState<T> extends State<RetryableAsyncWidget<T>> {
  late Future<T> _future;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _future = widget.futureBuilder();
  }

  void _retry() {
    if (_retryCount < widget.maxRetries) {
      setState(() {
        _retryCount++;
        _future = widget.futureBuilder();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingWidget ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          if (widget.errorBuilder != null) {
            return widget.errorBuilder!(context, snapshot.error);
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'エラーが発生しました',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                if (_retryCount < widget.maxRetries)
                  ElevatedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: Text('再試行 (${_retryCount + 1}/${widget.maxRetries})'),
                  )
                else
                  const Text(
                    '最大再試行回数に達しました',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('データがありません'));
        }

        return widget.builder(context, snapshot.data as T);
      },
    );
  }
}