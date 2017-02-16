%w(net/https uri json csv lol).each { |lib| require lib }
%w(kariudo game_logger add_summoner_name_to_game).each { |lib| require_relative 'kari/' + lib }

# 環境変数に設定しとく
RIOT_API_KEY = ENV['RIOT_API_KEY']
KARIBOT_WEBHOOK_URI = ENV['KARIBOT_WEBHOOK_URI']

# 全狩人のKariudoクラスのインスタンスの配列を返す
def fetch_kariudos
  kariudos = []
  CSV.foreach('kariudos.csv', headers: true) do |row|
    kariudos.push(Kariudo.new(row['id'].to_i, row['name']))
  end
  kariudos
end

# Riot APIより狩人達の最近のマッチを全て取得し, 未処理のものだけを返す
def fetch_recent_games(kariudos)
  client = Lol::Client.new(RIOT_API_KEY, region: 'jp')
  recent_games = []

  kariudos.each do |kariudo|
    client.game.recent(kariudo.id).each do |game|
      next if GameLogger.logged?(game.game_id)

      game.summoner_name = kariudo.name
      GameLogger.log(game.game_id)
      recent_games.push(game)
    end
  end
  recent_games
end

def get_kariudo_names_in_game(game, kariudos)
  kariudo_names_in_game_arr = [game.summoner_name]

  # 同じ試合に他に狩人がいれば追加
  unless game.fellow_players.nil?
    game.fellow_players.each do |player|
      if (kariudo = kariudos.find { |k| k.id == player.summoner_id })
        kariudo_names_in_game_arr.push(kariudo.name)
      end
    end
  end

  kariudo_names_in_game_arr.shuffle
end

WIN_COLOR_INT  = 3447003
LOSE_COLOR_INT = 15158332

# DiscordにPostする文章を返す
def build_embeds(recent_games, kariudos)
  embeds = []
  title_template = '%{kariudo_names_in_game} が%{result}。'
  desc_template = 'http://jp.op.gg/summoner/userName=%{kariudo_name}'

  recent_games.reverse.each do |recent_game|
    kariudo_names_in_game_arr = get_kariudo_names_in_game(recent_game, kariudos)

    title_params = {
      kariudo_names_in_game: kariudo_names_in_game_arr.join(', '),
      result: recent_game.stats.win ? '狩りました' : '狩られました'
    }

    desc_params = { kariudo_name: kariudo_names_in_game_arr.sample }

    embed = {
      title: format(title_template, title_params),
      description: format(desc_template, desc_params),
      color: recent_game.stats.win ? WIN_COLOR_INT : LOSE_COLOR_INT
    }
    embeds.push(embed)
  end

  embeds
end

def execute_discord_webhook(embeds)
  uri = URI.parse(KARIBOT_WEBHOOK_URI)
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true
  req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
  req.body = { embeds: embeds }.to_json
  res = https.request(req)
  puts "Response #{res.code} #{res.message}: #{res.body}"
end

# Kariudoクラスのインスタンスの配列
kariudos = fetch_kariudos

# Lol::Gameクラスのインスタンスの配列
recent_games = fetch_recent_games(kariudos)

# 最近のゲームが無ければDiscordにPOSTせず終了
if recent_games.empty?
  puts 'No recent games.'
  exit
end

embeds = build_embeds(recent_games, kariudos)
execute_discord_webhook(embeds)
