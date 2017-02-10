# 一度処理したGameのgame_idを保存する
class GameLogger
  LOG_FILE_PATH = 'recent_games.txt'.freeze

  class << self
    def logged?(match_id)
      init_log_file unless File.exist?(LOG_FILE_PATH)

      # 毎回ファイル開くのなんとかしたい
      File.readlines(LOG_FILE_PATH).map(&:chomp).include?(match_id.to_s)
    end

    def log(match_id)
      File.open(LOG_FILE_PATH, 'a+') { |f| f.puts(match_id) }
    end

    def init_log_file
      File.open(LOG_FILE_PATH, 'w')
    end
  end
end
