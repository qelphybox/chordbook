require 'telegram/bot'

def handle_message(bot, message)
  # TODO: Implement message handling
end

Telegram::Bot::Client.run(ENV['TG_API_TOKEN']) do |bot|
  bot.listen do |message|
    handle_message(bot, message)
  end
end
