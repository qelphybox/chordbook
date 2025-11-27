require 'telegram/bot'
require 'dotenv/load'
require_relative 'db'

DB.prepare_tables!

CONNECTION = SQLite3::Database.new('chordbook.db')
CONNECTION.results_as_hash = true

USER_STATE = {}
ADDING_SONG = {}
USER_STATE ||= {}


puts 'Loading handle_message...'
def handle_message(bot, message)
  puts "handle_message..."

  tg_id = message.from.id
  username = message.from.username

  puts "проверяем существует ли юзер"
  pp DB.user_exists?(tg_id)
  if !DB.user_exists?(tg_id)
    puts "юзера нет - создаем юзера"
    DB.create_user!(tg_id, username)
    puts "добавляем юзеру базовые песни"
    DB.add_basic_songs!(tg_id)
  end

  if message.text == '/start' # message - объект, который пришел из обработчика Tg-бота (например библиотека telegram-bot-ruby)
    bot.api.send_message(chat_id: message.chat.id, text: 'привет! я бот для хранения библиотеки аккордов')
    return
  end

    # message.chat.id - id чата
    # message.from.id - id пользователя
    # message.text - текст сообщения 

  if message.text.start_with?('/song') # message.text = /song pixies
    query = message.text.split('/song').last # 'pixies'
    if query.nil?
      bot.api.send_message(chat_id: message.chat.id, text: "введите название песни таким образом\n /song where is my mind")
      return
    end
    query = query.strip
    songs = DB.search_songs!(query) # => SQLite3::ResultSet
     puts songs.inspect

    # FIXME: пока что не работает, не понятно как работать с SQLite3::ResultSet
    
    songs = songs.to_a
    if songs.empty?
      bot.api.send_message(chat_id: message.chat.id, text: 'песня не найдена')
      return
    end

    message_text = ""
    songs.each do |song|
      #  bot.api.send_message(chat_id: message.chat.id, text: "#{song[:artist]} - #{song[:title]}")
      message_text += "#{song[1]} - #{song[2]}"
    end
    bot.api.send_message(
      chat_id: message.chat.id,
      text: message_text
    )
  end

  # if message.text == '/create_song'
  #   bot.api.send_message(chat_id: message.chat.id, text: "Введите название песни и аккорды, чтобы добавить\n Пример: song - chords")
  # end

  
  
  if message.text == '/add_song'
    USER_STATE[message.chat.id] = :waiting_for_artist 
    bot.api.send_message(
      chat_id: message.chat.id,
      text: "Введите имя артиста."
    )
    return
  end
  
  if USER_STATE[message.chat.id] == :waiting_for_artist
    ADDING_SONG[message.chat.id] = {artist: message.text.strip} # ADDING_SONG = {} -> ADDING_SONG = {1: {artist: "Pixies"}}  
    USER_STATE[message.chat.id] = :waiting_for_title
    bot.api.send_message(
      chat_id: message.chat.id,
      text: "Введите название песни."
    )
    return
  end

  if USER_STATE[message.chat.id] == :waiting_for_title
    ADDING_SONG[message.chat.id][:title] = message.text.strip  # ADDING_SONG = {1: {artist: "Pixies"}} -> ADDING_SONG = {1: {artist: "Pixies", song: "Wonderwall"}}
    USER_STATE[message.chat.id] = :waiting_for_chords
    bot.api.send_message(
      chat_id: message.chat.id,
      text: "Введите аккорды песни."
    )
    return
  end
  
  
  # show_song
  
  
  if message.text.start_with?('/show_song')
    id = message.text.split('/show_song').last
    if id.empty?
      bot.api.send_message(chat_id: message.chat.id, text: "песня не найдена")
      return
    end
    id = id.strip
    result_song = DB.find_song_by_id!(id) # id = 1
    result_song = result_song.to_a # [[1, 'Wonderwall', 'Pixies', 'Am, Dm, E']]
    if result_song.empty? # false
      bot.api.send_message(chat_id: message.chat.id, text: 'песня не найдена')
      return
    end
    
    song = result_song.first # [1, 'Wonderwall', 'Pixies', 'Am, Dm, E']
    title = song[1]
    artist = song[2]
    chords = song[3]
    bot.api.send_message(chat_id: message.chat.id, text: "#{artist} - #{title}\n#{chords}")
    return
  end
end





Telegram::Bot::Client.run(ENV['TG_API_TOKEN']) do |bot|
  bot.listen do |message|
    puts 'run handle_message...'
    handle_message(bot, message)
  end
end




# puts 'Bye... Bye...'
