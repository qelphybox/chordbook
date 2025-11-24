require 'telegram/bot'
require 'dotenv/load'
require_relative 'db'

DB.prepare_tables!

CONNECTION = SQLite3::Database.new('chordbook.db')
CONNECTION.results_as_hash = true

USER_STATE = {}

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

  # if message.text == '/create_song'
  #   bot.api.send_message(chat_id: message.chat.id, text: "Введите название песни и аккорды, чтобы добавить\n Пример: song - chords")
  # end

  
  
  if message.text == '/create_song'
    USER_STATE[message.chat.id] = :waiting_for_song 
      chat_id: message.chat.id,
      text: "Введите название песни и аккорды.\nПример:\nWonderwall - Em G D A"
      )
    return
  end

  if USER_STATE[message.chat.id] == :waiting_for_song # проверка текущего состояния пользователя по chat.id в хеше/константе USER STATE
    # если состояние равно символу :waiting_for_song, значит бот ожидает от этого пользователя строки с названием песни и аккордами, и выполняется код внутри if
    input = message.text # текст входного сообщения сохраняется в переменную. Это строка, которую написал пользователь

    if input.include?('-') # проверка: содержит ли введённая строка символ '-'
      # Это простая валидация формата - мы ожидаем Название - Аккордыю Если '-' есть, идём в ветку if; иначе - в else
      title, chords = input.split('-', 2).map(&:strip) # разбиваем строку по первому - на макс. 2 фрагмента (название и остаток)
      # ограничение 2 важно: если аккорды содержат '-', это не будет ломать разбор
      # map(&:strip) - убирает пробелы по краям у каждой части
      # title, chords = -> присваивает превую чатсь в title, вторую в chords

      DB::Songs.add(title: title, chords: chords) # вызываем метод/модуль, который сохраняет песню в базу данных
      # DB::Songs - модуль или пространство имён, add - метод, принимающий именованные аргументы title: и сhords:
      # внутри обычно выполняется SQL INSERT

      USER_STATE.delete(message.chat.id) # убирает состояние пользователя из USER_STATE, значит пользователь уже не в режиме ввода песни (выход из состояния ожидания)
      # это важно, чтобы дальнейшие сообщения не воспринимались как аккорды

      bot.api.send_message( 
        chat_id: message.chat.id, # куда отправлять
        text: "Песня успешно добавлена!\n\n#{title} - #{chords}" # text: сообщение: включает название и аккорды, подставляемые через интерполяцию #{...}. \n\n - 2 переноса строки для форматирования
      ) # бот отправляет подтверждение пользователю 
    else bot.api.send_message( # альтернативная ветка: срабатывает если input.include?('-') вернул false
      chat_id: message.chat.id,
      text: "Неверный формат. Используйте: Название - Аккорды"
    )
    end
    return
  end
end

# end


Telegram::Bot::Client.run(ENV['TG_API_TOKEN']) do |bot|
  bot.listen do |message|
    puts 'run handle_message...'
    handle_message(bot, message)
  end
end
 



# puts 'Bye... Bye...'
