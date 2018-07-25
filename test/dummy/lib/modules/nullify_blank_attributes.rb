module NullifyBlankAttributes

  def write_attribute(attr_name, value)
    new_value = value == false ? false : value.presence
    super(attr_name, new_value)
  end

end
