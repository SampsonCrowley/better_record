class Integer
  def cents
    StoreAsInt.money(self)
  end
end
