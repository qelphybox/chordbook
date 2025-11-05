require 'telegram/bot'
require 'dotenv/load'
require_relative 'db'

DB.prepare_tables!

puts 'Loading handle_message...'
def handle_message(bot, message)
  puts "handle_message..."
  pp message

  tg_id = message.from.id
  username = message.from.username

  if !DB.user_exists?(tg_id)
    DB.create_user!(tg_id, username)
    DB.add_basic_songs!(tg_id)
  end

  if message.text == '/start'
    bot.api.send_message(chat_id: message.chat.id, text: 'привет! я бот для хранения библиотеки аккордов')
    return
  end

  if message.text.start_with?('/song')
    query = message.text.split('/song').last.strip # 'where is my mind'

    # query: 'where is my mind' | 'pixies'
    # return: [{ title: 'Where is my mind', artist: 'Pixies', chords: 'Am Dm E' }]
    songs = DB.search_songs!(query) # => SQLite3::ResultSet
    puts songs.inspect

    # FIXME: пока что не работает, не понятно как работать с SQLite3::ResultSet
    # if songs.empty?
    #   bot.api.send_message(chat_id: message.chat.id, text: 'песня не найдена')
    #   return
    # end

    # songs.each do |song|
    #   bot.api.send_message(chat_id: message.chat.id, text: "#{song[:artist]} - #{song[:title]}")
    # end
  end

end


Telegram::Bot::Client.run(ENV['TG_API_TOKEN']) do |bot|
  bot.listen do |message|
    puts 'run handle_message...'
    handle_message(bot, message)
  end
end

puts 'Bye... Bye...'
