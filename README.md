# Chordbook 

Бот для хранения библиотеки аккордов

## Как запускать?

1. сходи в https://t.me/BotFather за своим токеном
2. `cp .env.sample .env` и заполни `.env` со своим ключом
3. установить sqlite3 - в консоли выполни `sudo apt install sqlite3`
4. выполни в консоли `bundle install`

```bash
bundle exec ruby chordbook.rb
```


## Что умеет

1. найти песни
```
user: /song where is my mind
bot:  <artist> - <title> <show_song_btn>
```
1. показать песню - дописать
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
1. редактировать песню - ДЗ
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



----------------------------------------
REFACTOR

1. show_song <id>
2. edit_song <id>
3. delete_song <id>
4. search_songs <query>
5. add_song


----------------------------------------

users
-----
id:integer:serial
tg_chat_id:string:null_false
state:string:null_false,default: 'chatting', options: [chatting, add_song-waiting_chords, add_song-waiting_title, add_song-waiting_artist, edit_song-waiting_chords, edit_song-waiting_title, edit_song-waiting_artist]

add_index [id tg_chat_id], uniue;

draft_songs
-----------
id:integer:serial
user_id:integer:null_false
song_id:null_true
artist:string
title:string
chords:text

add_index [id, user_id], unique: true

songs
-----
id:integer:serial
user_id:integer:null_false
artist:string
title:string
chords:text

-------------------------------------------

user: add_song
bot: Дайте название артиста
user: Pixies # -> draft_song(artist: "Pixies", user: user.id)

user: edit_song <id> # -> draft_song(user: user.id, song.id)
bot: Дайте новое название артиста

--------------------------------------------


db:
  sqlite_result_set = sqlite.execute('SELECT * FROM users WHERE id = ? LIMIT 1', [id])
  sqlite_result_set # -> [[1, 234234, 'chatting']]
  user = { id: 1, tg_chat_id: 234234, state: 'chatting' }
  user[:id]
  user[:tg_chat_id]

orm: object relation mapping
  
class User 
    # sqlite
  attribute :id
  attribute :tg_chat_id
    ...
end


user = User.find(1) # sqlite.execute('SELECT * FROM users WHERE id = ? LIMIT 1', [id])
User.where()
user.id
user.tg_chat_id


---------------------------------------------

orm way: описываем модельки, работаем с данными/бд через модели
plain way: 

module DB
  def create_user(tg_chat_id, state)
    sqlite.execute
    return user # { id: , tg_chat_id, state }
    raise error if user alre exists
  end 

  def get_user(tg_chat_id)
     sqlite.execute
     return user {} | nil
  edf
end

-----------------------------------------------

# TODO: ЗАВЕСТИ ДРАЙВ С ЗАПИСКАМИ
