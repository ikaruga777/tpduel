# ⌨️ Type Duel

1v1 リアルタイムタイピング対戦ゲーム。

表示されたお題の文を、相手より速く正確に入力し切ったほうが勝ち。
片方が部屋を作り、URL を相手に共有して 2 人で対戦します。アカウント登録は不要、
ニックネームだけの匿名プレイです。

## 遊び方

1. トップでニックネームを入力して「部屋を作る」
2. 表示されたルームコード / 共有 URL を対戦相手に送る
3. 相手が URL を開いてニックネームを入れて入室
4. 2 人揃ったらホストが「スタート」→ カウントダウン → お題表示
5. お題の文をタイプ。先に全文を正しく打ち切ったプレイヤーの勝ち
6. 「もう一度」で同じ部屋で再戦（新しいお題）

入力中はお互いの進捗バーがリアルタイムに伸びていきます。文字は正しければ緑、
ミスは赤でハイライトされ、全文を正しく打ち切ると勝敗が確定します。

## 技術構成

- **Rails 8**（標準構成）
- **SQLite**（開発・本番とも）
- **Solid Cable**（DB バックの ActionCable アダプタ）でリアルタイム通信
- **Hotwire / Turbo + Stimulus**、JS は **importmap**
- アカウント登録なし（ニックネームのみの匿名プレイ。署名付き Cookie でプレイヤーを識別）

Solid Cable は配信が DB 経由のため、2 人対戦の MVP には十分です。高頻度・低レイテンシが
必要になったら Redis アダプタへ差し替え可能です（`config/cable.yml`）。

### データベース構成

開発・本番とも、リアルタイム配信用に Solid Cable 専用の SQLite データベースを
分けたマルチ DB 構成です。

| データベース | 用途 | テーブル |
| --- | --- | --- |
| `primary` (`storage/development.sqlite3`) | アプリ本体 | `rooms`, `players` |
| `cable` (`storage/development_cable.sqlite3`) | Solid Cable のメッセージ配信 | `solid_cable_messages` |

### 主なコンポーネント

| 種類 | ファイル | 役割 |
| --- | --- | --- |
| Model | `app/models/room.rb` | 部屋・対戦状態・勝者判定 |
| Model | `app/models/player.rb` | プレイヤー（ニックネーム・進捗） |
| Model | `app/models/prompt.rb` | お題の文（ランダム抽選） |
| Controller | `app/controllers/rooms_controller.rb` | 部屋の作成・入室 |
| Channel | `app/channels/room_channel.rb` | スタート / 進捗 / 完了の中継 |
| Stimulus | `app/javascript/controllers/game_controller.js` | 対戦画面・タイピング判定 |

## セットアップ

前提: Ruby 3.3.x

```bash
# 依存 gem をインストール
bundle install

# データベースを作成（primary と cable の両方）
bin/rails db:prepare

# 開発サーバーを起動
bin/rails server
```

ブラウザで http://localhost:3000 を開きます。

対戦を試すには、別のブラウザ（またはシークレットウィンドウ）で同じ部屋の
共有 URL を開いてください。プレイヤーは署名付き Cookie で識別されるため、
同一ブラウザの別タブは同じプレイヤー扱いになります。

## お題について

現在のお題は、IME を介さず 1 文字ずつの正誤判定が確実に動くように英文（ASCII）です。
`app/models/prompt.rb` の `SENTENCES` を編集すれば自由に追加・変更できます。

> 日本語（IME 入力）のお題に対応する場合は、`compositionstart` / `compositionend`
> を考慮した入力処理への拡張が必要です（今後の課題）。

## 動作確認

ゲームロジックとリアルタイム中継は付属のスモークテストで確認できます。

```bash
bin/rails runner script/smoke_test.rb
```
