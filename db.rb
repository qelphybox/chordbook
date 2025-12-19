require "sqlite3"

module DB
  class << self
    def prepare_tables
      conn = SQLite3::Database.new(db_file)
      conn.query <<~SQL
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tg_chat_id TEXT NOT NULL,
          state TEXT NOT NULL
        );
        CREATE UNIQUE INDEX IF NOT EXISTS tg_chat_id_uniq_index ON users (tg_chat_id);

        CREATE TABLE IF NOT EXISTS draft_songs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          song_id INTEGER,
          artist TEXT,
          title TEXT
          chords TEXT
        );

        CREATE UNIQUE INDEX IF NOT EXISTS user_draft_song_unique_index ON users (user_id);

        CREATE TABLE IF NOT EXISTS songs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          artist TEXT,
          title TEXT,
          chords TEXT,
        );

      SQL
    end

    def drop_db
      File.delete(db_file) if File.exist?(db_file)
    end

    # param: tg_chat_id(integer) - id юзера в телеге
    # param: state(string) - состояние чата с юзером

    # return: hash - данные юзера с айдишником из базы { id: 1, tg_chat_id: 234234, state: 'chatting" }

    # raises:

    # user_exists - если юзер уже существует, мы не можем создать его

    def create_user(tg_chat_id, state) # user = {} -> возвращает
      result = connection.query <<~SQL, [tg_chat_id, state]
        INSERT INTO users (tg_chat_id, state)
        VALUES (?, ?)
        RETURNING * ;
      SQL

      result.next_hash
    end

    # param: user_id(integer) - id юзера - владельца песни
    # param: artist(string) - название группы
    # param: title(string) - название песни
    # param: chords(string) - аккорды песни

    # return - объект песни из DB -> hash = { user_id: 1, id: 1, artist: "Pixies", title: "Wonderwall", chords: "Am, Em, Dm"} -> пример

    def create_song(user_id, artist, title, chords)
    end

    # param: id - id песни в DB
    # return - hash = { } объект песни из DB -> пример : hash = { artist: "Pixies", title: "Wonderwall", chords: "Am, Em, Dm" }
    def get_song(id)
    end

    # param: id(integer) - id песни в DB
    # param: artist(string) - новое название группы
    # param: title(string) - новое название песни
    # param: chords(string) - новые аккорды песни

    # return - hash - объект песни из DB
    # raises:
    # song_not_found - песня не найдена id не существует в таблице

    def update_song(id, artist, title, chords)
    end

    private

    def connection
      @connection ||= SQLite3::Database.new(db_file)
    end

    APP_ENV = ENV["APP_ENV"] || "development"
    def db_file
      @db_file ||= "chordbook_#{APP_ENV}.db"
    end
  end
end
