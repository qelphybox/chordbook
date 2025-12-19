require "sqlite3" # подключение библиотеки sqlite 3, которая позволяет работать с базой данный SQLite из Ruby

# DOC: https://github.com/sparklemotion/sqlite3-ruby

module DB # объявление модуля DB, Модуль в Ruby - это пространство имён, контейнер для методов и констант, здесь используется, чтобы собрать все методы работы с БД в одном месте
  CONNECTION = SQLite3::Database.new("chordbook.db") # создание объекта подключения к базе данных SQLite с именем chordbook.db. Если файл базы не существует, SQLite создаст его автоматически. CONNECTION - это константа модуля, через которую будут выполняться все запросы

  def self.prepare_tables! # объявление метода prepare_tables! для модуля DB, self. означает, что это метод модуля, а не экземпляра
    CONNECTION.query <<~SQL
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tg_id TEXT,
        username TEXT
      )
    SQL

    #  SQL-запрос создает таблицу users, если она не существует
    # поля:
    # id - уникальный идентификатор пользователя, автоматически увеличивается
    # tg_id - telegram id пользователя (текст)
    # username - имя пользователя (текст)

    # NOTE: это делается для того, чтобы нельзя было создать двух пользователей
    #       с одним и тем же tg_id

    CONNECTION.query <<~SQL
      CREATE UNIQUE INDEX IF NOT EXISTS idx_users_tg_id ON users (tg_id)
    SQL

    # создается уникальный индекс на столбец tg_id
    # это предотвращает добавление двух пользователей с одинаковым tg_id

    CONNECTION.query <<~SQL
      CREATE TABLE IF NOT EXISTS songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        artist TEXT,
        chords TEXT,
        user_id INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    SQL
  end

  # создается таблица songs для хранения песен
  # поля:
  # id - уникальный идентификатор песни
  # title - название песни
  # artist - исполнитель
  # chords - аккорды песни
  # user_id - внешний ключ на таблицу users (чья это песня)
  # FOREIGN KEY обеспечивает связь между песнями и пользователями

  def self.add_basic_songs!(user_id) # метод добавляет базовые песни для конкретного пользователя (user_id)
    songs = [
      {title: "Where is my mind", artist: "Pixies", chords: "Am Dm E"},
      {title: "Man in the Box", artist: "Alice in Chains", chords: "Am Dm E"},
      {title: "Smells Like Teen Spirit", artist: "Nirvana", chords: "Am Dm E"},
      {title: "Enter Sandman", artist: "Metallica", chords: "Am Dm E"},
      {title: "Thunderstruck", artist: "AC/DC", chords: "Am Dm E"},
      {title: "Back in Black", artist: "AC/DC", chords: "Am Dm E"}
    ]

    # создается массив хэшей с базовыми песнями (название, исполнитель, аккорды)

    songs.each do |song|
      CONNECTION.query <<~SQL, [song[:title], song[:artist], song[:chords], user_id]
        INSERT INTO songs (title, artist, chords, user_id)
          VALUES (?, ?, ?, ?)
        ON CONFLICT DO NOTHING 
      SQL
    end
  end

  # для каждой песни выполняется SQL-запрос на вставку в таблицу songs
  # используются плейсхолдеры ? для предотвращения SQL-инъекций. чтобы никакой пользовательский ввод не смог изменить структуру SQL-запроса
  # SQL-инъекция — это уязвимость в приложениях, которая позволяет злоумышленнику «вставлять» свой SQL-код в запрос к базе данных. Если запрос формируется небезопасно (например, просто склеиванием строк), злоумышленник может изменить логику запроса и получить доступ к данным, которые он не должен видеть, или даже удалить/изменить данные.
  # ON CONFLICT DO NOTHING - если такая песня уже есть, она не вставляется повторно

  def self.user_exists?(tg_id)
    CONNECTION.get_first_value(
      "SELECT COUNT(*) FROM users WHERE tg_id = ?",
      tg_id
    ).to_i > 0
  end

  # возвращает количество записей с этим tg_id (0 или 1)

  def self.create_user!(tg_id, username) # метод создает нового пользователя
    CONNECTION.query <<~SQL, [tg_id, username]
      INSERT INTO users (tg_id, username) VALUES (?, ?)
    SQL
  rescue SQLite3::ConstraintException
    raise "User with tg_id #{tg_id} already exists"
  end

  def self.get_user!(tg_id)
    CONNECTION.query <<~SQL, [tg_id] # обращение в БД
      SELECT *
      FROM users
      WHERE tg_id = ?
    SQL
  end

  # если пользователь с таким tg_id уже существует, SQLite выбросит ConstraintException, ошибка, говорящая о том, что пользователь с таким id уже существует

  def self.search_songs!(query) # метод ищет песни по названию и исполнителю
    CONNECTION.query <<~SQL, ["%#{query}%", "%#{query}%"]
      SELECT id, title, artist, chords
      FROM songs
      WHERE title LIKE ?
         OR artist LIKE ?
    SQL
  end

  def self.find_song_by_id!(id) # метод ищет песни по названию и исполнителю
    CONNECTION.query <<~SQL, [id]
      SELECT id, title, artist, chords
      FROM songs
      WHERE id = ?
    SQL
  end

  def update_song!(id, artist, title, chords)
    CONNECTION.query <<~SQL, [artist, title, chords, id]
      UPDATE songs
      SET artist = ?, title = ?, chords = ?
      WHERE id = ?
    SQL
  end
end

# используетс SQL LIKE с %, чтобы искать подстроку в любом месте текста
# возвращает список совпавших песен с их ID, названием, исполнителем и аккордами

module DB
  module Songs
    def self.add(user_id:, artist:, title:, chords:)
      CONNECTION.execute(
        "INSERT INTO songs (user_id, artist, title, chords) VALUES (?, ?, ?, ?)",
        [user_id, artist, title, chords]
      )
    end
  end
end
