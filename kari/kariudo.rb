# id, nameアクセサが欲しいだけのクラス
class Kariudo
  attr_accessor :id, :name

  def initialize(id, name)
    @id = id
    @name = name
  end
end
