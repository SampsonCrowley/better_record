class Date
  def month_name
    Date::MONTHNAMES[month]
  end

  def self.today
    current
  end
end
