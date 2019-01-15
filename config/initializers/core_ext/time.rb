class Time
  include GlobalID::Identification

  def id
    iso8601
  end

  def self.find(time)
    time.is_a?(Integer) ? Time.zone.at(time) : Time.zone.parse(time)
  end
end
