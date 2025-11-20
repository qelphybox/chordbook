require 'telegram/bot'
require 'dotenv/load'
require_relative 'db'

DB.prepare_tables!

CONNECTION = SQLite3::Database.new('chordbook.db')
CONNECTION.results_as_hash = true

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

  if message.text == '/start'
    bot.api.send_message(chat_id: message.chat.id, text: 'привет! я бот для хранения библиотеки аккордов')
    return
  end

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
    pp "-----------"
    pp songs = songs.to_a
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
end

# end


Telegram::Bot::Client.run(ENV['TG_API_TOKEN']) do |bot|
  bot.listen do |message|
    puts 'run handle_message...'
    handle_message(bot, message)
  end
end
 



puts 'Bye... Bye...'
