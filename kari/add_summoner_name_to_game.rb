# ゲームのオブジェクトにそのゲームを検索するために使用したサモナーのid及び名前が含まれていない
# 含めるようにライブラリのクラスを再オープンする
module Lol
  # 再オープンしてアクセサ追加
  class Game < Lol::Model
    attr_accessor :summoner_name
  end
end
