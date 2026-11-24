# App Store の掲載文（en：英語・既定の言語）

文字数の上限は App Store Connect の制限（アプリ名 30 文字、サブタイトル 30 文字、プロモーションテキスト 170 文字、キーワード 100 文字、説明文 4,000 文字）。
見出しはスクリプトが探すので日本語のまま変えない。各見出しの下の最初のコードブロックが登録される文面。

言葉の選び方: アニメ・アイドルのファンの間で通じる "oshi" をそのまま使い、初出で "fave"・"bias"（K-POP の言い方）を添えた。
推し色は "member color"、予定は "event"。
英語圏で "oshi" はほとんど検索されない（K-POP のファンは "bias"）ので、アプリ名の "Oshi" は残し、検索の語（K-pop・concert・birthday・bias・idol・D-day）はサブタイトルとキーワードで取る（1.3.0）。

## アプリ名（30 文字まで）

```
Oshi Countdown: Fan Event Days
```

（30 文字）

## サブタイトル（30 文字まで）

```
K-pop concert & birthday timer
```

（30 文字）

## プロモーションテキスト（170 文字まで）

```
New: Oshi Countdown Plus puts your oshi's photo on widgets and app backgrounds (yearly: 1-week free trial). Share countdowns as images, free. Free features stay free.
```

（166 文字）

1.3.0 の告知（Plus とシェア）。検索には効かないので、キーワードは並べない。価格の数字は書かない。

## 説明文（4,000 文字まで）

```
Count down the days to your oshi's concerts, birthdays, release days and streams. On the big day, a Live Activity on your Lock Screen and in the Dynamic Island counts down to showtime, for free.

◆ Countdown to showtime on the big day
For events with a start time, the Live Activity starts 3 hours before, so you can check the time left without opening the app.

◆ Countdowns in your oshi's color
Add your oshi (your fave, your bias) with their name and member color, and their events and countdowns appear in that color. Use a photo of your oshi as their avatar, and put your oshi in any order: the app and widgets take on the color of the oshi at the top.

◆ Your next event, down to the second
The nearest event is shown large at the top of Home. Open an event to watch the days, hours, minutes and seconds tick down. Pin your most important event and filter by oshi.

◆ Events that repeat every year
Set birthdays and anniversaries to repeat every year, and the app counts down to the same date next year. Events on February 29 are counted on February 28 in non-leap years.

◆ Home Screen and Lock Screen widgets
• Countdown: days left until one event you choose (also on the Lock Screen)
• Oshi Count: your upcoming events, nearest first

◆ Reminders before your events
Get notified 30 days, 7 days and 1 day before, on the day, and 1 hour before the start time. Change the timings and the time of day in Settings.

◆ Share your countdown as an image
Turn "N days left" into a square card with your oshi's photo and member color, and share it anywhere. The image is created on your device.

◆ Oshi Countdown Plus (paid)
• Oshi Photo widget: your oshi's photo behind the days left
• Custom backgrounds & decorations: dress up the app with your oshi's photos
Choose a monthly or yearly subscription (yearly includes a 1-week free trial) or a one-time purchase, which also covers Plus features added later.
Everything that's free today, including countdowns, widgets, reminders, Live Activities and sharing, stays free. We won't move it behind Plus.

◆ iPhone and iPad, no ads, data on your device
Works on iPhone and iPad, with Dark Mode. No ads and no account. Your oshi, photos and events are stored only on your device and are never sent anywhere.
(They're included in device backups to iCloud or a computer, and erased when you delete the app.)

About subscriptions
• Payment is charged to your Apple Account at confirmation of purchase. Subscriptions renew automatically unless canceled at least 24 hours before the end of the current period, and renewal is charged within the 24 hours before it ends.
• The free trial turns into a paid yearly subscription unless canceled at least 24 hours before it ends.
• Manage or cancel in Settings > [your name] > Subscriptions.
• After a subscription ends, the app returns to the standard look and keeps the photos you chose.

Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://shilokuma.jp/privacy/oshikatsu-countdown/
```

（3028 文字）

冒頭の 1〜2 文は「more」を押さなくても読めるので、競合に無い「当日は開演まで Dynamic Island とロック画面で秒読み（無料）」を入れた。
Plus は審査ガイドライン 2.3.2・3.1.2 に合わせ、自動更新・お試しのあとの課金・解約の方法を書いた。価格の数字は書かない。
説明文は検索には効かないが、米国のストアの App Store のタグ（App tags）は `en-US` のメタデータから付くので、K-POP・ウィジェット・ライブアクティビティの語を自然な文で入れている。

## キーワード（100 文字まで・カンマ区切り）

アプリ名・サブタイトルの語（oshi, countdown, fan, event, days, concert, birthday, timer など）は外した。
サブタイトルの "K-pop" がハイフンのない "kpop" の検索に効くかは分からないので、"kpop" はキーワードにも残した。

```
bias,idol,kpop,dday,widget,live,photo,anniversary,release,stream,stan,otaku,vtuber,comeback,fandom
```

（98 文字）
