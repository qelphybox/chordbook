# Chordbook 

Бот для хранения библиотеки аккордов

## Как запускать?

1. сходи в https://t.me/BotFather за своим токеном
2. `cp .env.sample .env` и заполни `.env` со своим ключом

```bash
bundle exec ruby chordbook.rb
```


## Что умеет

1. найти песни
```
user: /song where is my mind
bot:  <artist> - <title> <show_song_btn>
```
1. показать песню
```
user: /show_song <id>
bot: <artist> - <title>
     <chords>
     <edit_song_btn>
```
1. добавить песню
```
user: /add_song
bot: Напиши имя артиста
user: pixies
bot: Напиши название песни
user: where is my mind
bot: Напиши аккорды песни
user: Am Dm E
```
1. редактировать песню
```
user: /edit_song <id>
bot: Напиши новое имя артиста + <skip_btn>
user: pixies
bot: Напиши новое название песни + <skip_btn>
user: where is my mind
bot: Напиши новые аккорды песни + <skip_btn>
user: Am Dm E
```

1. удалить песню
```
user: /delete_song <id>
bot: Песня <artist> - <title> удалена
```