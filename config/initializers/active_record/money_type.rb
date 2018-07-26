class MoneyType < ActiveRecord::Type::Value
  def cast(value)
    return nil unless value
    convert_to_money(value)
  end

  def deserialize(value)
    super(convert_to_money(value))
  end

  def serialize(value)
    new_val = convert_to_money(value)
    super(new_val ? new_val.value : nil)
  end

  private
    def convert_to_money(value)
      return nil unless value
      if (!value.kind_of?(Numeric))
        begin
          dollars_to_cents = (value.gsub(/\$/, '').presence || 0).to_d * 100
          StoreAsInt.money(dollars_to_cents.to_i)
        rescue
          StoreAsInt::Money.new
        end
      else
        StoreAsInt.money(value)
      end
    end
end

ActiveRecord::Type.register(:money_column, MoneyType)
