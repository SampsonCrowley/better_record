# frozen_string_literal: true

class Date
  include GlobalID::Identification

  def month_name
    Date::MONTHNAMES[month]
  end

  def self.today
    current
  end

  alias_method :id, :to_s
  def self.find(str)
    parse(str)
  end
end
