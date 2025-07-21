import 'package:flutter/foundation.dart';

/// 全てのViewModelで使用する基底クラス
/// 共通のローディング状態とエラーハンドリングを提供
abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  /// ローディング状態のゲッター
  bool get isLoading => _isLoading;

  /// エラーメッセージのゲッター
  String? get errorMessage => _errorMessage;

  /// ViewModelが破棄されているかどうか
  bool get isDisposed => _isDisposed;

  /// ローディング状態を設定
  void _setLoading(bool loading) {
    if (_isDisposed) return;
    _isLoading = loading;
    notifyListeners();
  }

  /// エラーメッセージを設定
  void _setError(String? error) {
    if (_isDisposed) return;
    _errorMessage = error;
    notifyListeners();
  }

  /// エラーをクリア
  void clearError() {
    if (_errorMessage != null) {
      _setError(null);
    }
  }

  /// 非同期処理をローディング状態とエラーハンドリング付きで実行
  Future<T?> executeWithLoading<T>(
    Future<T> Function() operation, {
    String? errorPrefix,
  }) async {
    _setLoading(true);
    try {
      final result = await operation();
      _setError(null);
      return result;
    } catch (e) {
      final errorMessage = errorPrefix != null 
          ? '$errorPrefix: $e'
          : e.toString();
      _setError(errorMessage);
      debugPrint('Error in $runtimeType: $errorMessage');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
} 