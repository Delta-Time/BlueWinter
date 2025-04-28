# BlueWinter

BlueWinterは、Mastodonクライアントアプリケーションです。シンプルなUIでタイムライン閲覧や投稿機能を提供します。

## セットアップ方法

### 必要な環境

- Flutter 3.0.0以上
- Dart 2.17.0以上
- Android Studio または Visual Studio Code

### インストール手順

1. リポジトリをクローンします

```bash
git clone https://github.com/yourusername/BlueWinter.git
```

2. 依存関係をインストールします

```bash
cd b_winter
flutter pub get
```

3. アプリを実行します

```bash
flutter run
```

## 使用方法

### 初回起動時

1. アプリを起動すると、ログイン画面が表示されます
2. MastodonのインスタンスURLとアクセストークンを入力してください
   - インスタンスURL例: https://mastodon.social
   - アクセストークン: MastodonのWebサイト設定から取得できます

### 主な機能

- **タイムライン閲覧**: ホーム、ローカル、連合タイムラインを切り替えて表示
- **投稿詳細**: 投稿をタップすると詳細が表示されます
- **コンテンツ警告(CW)**: 警告付きコンテンツの表示・非表示を切り替えられます
- **リアクション**: お気に入り登録、ブースト、返信が可能です
- **ダークモード**: 設定画面からテーマを切り替えられます

### 注意事項

- 本アプリは開発中のため、一部機能が制限されている場合があります
- APIの制限によりタイムラインの更新頻度に制限がある場合があります

## 開発情報

- フレームワーク: Flutter
- 状態管理: Provider
- ストレージ: shared_preferences, flutter_secure_storage
- 開発手法: バイブコーディング（AI支援による高速開発）
- 使用AI: Claude 3.7 Sonnet

## 問題報告

バグや機能リクエストは、GitHubのIssuesに報告してください。
