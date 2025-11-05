require 'sqlite3'

# DOC: https://github.com/sparklemotion/sqlite3-ruby

module DB
  CONNECTION = SQLite3::Database.new('chordbook.db')

  def self.prepare_tables!
    CONNECTION.query <<~SQL
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tg_id TEXT,
        username TEXT
      )
    SQL

    # NOTE: это делается для того, чтобы нельзя было создать двух пользователей
    #       с одним и тем же tg_id
    CONNECTION.query <<~SQL
      CREATE UNIQUE INDEX IF NOT EXISTS idx_users_tg_id ON users (tg_id)
    SQL

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

  def self.add_basic_songs!(user_id)
    songs = [
      { title: 'Where is my mind', artist: 'Pixies', chords: 'Am Dm E' },
      { title: 'Man in the Box', artist: 'Alice in Chains', chords: 'Am Dm E' },
      { title: 'Smells Like Teen Spirit', artist: 'Nirvana', chords: 'Am Dm E' },
      { title: 'Enter Sandman', artist: 'Metallica', chords: 'Am Dm E' },
      { title: 'Thunderstruck', artist: 'AC/DC', chords: 'Am Dm E' },
      { title: 'Back in Black', artist: 'AC/DC', chords: 'Am Dm E' },
    ]

    songs.each do |song|
      CONNECTION.query <<~SQL, [song[:title], song[:artist], song[:chords], user_id]
        INSERT INTO songs (title, artist, chords, user_id)
          VALUES (?, ?, ?, ?)
        ON CONFLICT DO NOTHING
      SQL
    end
  end

  def self.user_exists?(tg_id)
    CONNECTION.query <<~SQL, tg_id
      SELECT COUNT(*) FROM users WHERE tg_id = ?
    SQL
  end

  def self.create_user!(tg_id, username)
    CONNECTION.query <<~SQL, tg_id, username
      INSERT INTO users (tg_id, username) VALUES (?, ?)
    SQL
  rescue SQLite3::ConstraintException
    raise "User with tg_id #{tg_id} already exists"
  end

  def self.search_songs!(query)
    CONNECTION.query <<~SQL, [ "%#{query}%", "%#{query}%" ]
      SELECT id, title, artist, chords
      FROM songs
      WHERE title LIKE ?
         OR artist LIKE ?
    SQL
  end
end
