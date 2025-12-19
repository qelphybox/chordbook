ENV['APP_ENV'] = 'test'
require 'minitest/autorun'
require_relative '../db2.rb'


class DB2Test < Minitest::Test
  def setup
    DB.drop_db
    DB.prepare_tables
  end

  def test_create_user
    user = DB.create_user(123, 'chatting')
    expected_user =  { "id" => 1, "tg_chat_id" => "123", "state" => "chatting" }
    assert_equal expected_user, user
  end

#   def test_that_kitty_can_eat
#     assert_equal "OHAI!", @meme.i_can_has_cheezburger?
#   end

#   def test_that_it_will_not_blend
#     refute_match /^no/i, @meme.will_it_blend?
#   end

#   def test_that_will_be_skipped
#     skip "test this later"
#   end
end
