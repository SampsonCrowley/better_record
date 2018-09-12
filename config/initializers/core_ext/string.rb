# frozen_string_literal: true

class String
  def self.clean_certificate(str)
    CGI.unescape(str).gsub(/(\n|-----(BEGIN|END) CERTIFICATE-----)/, '').strip
  end

  def clean_certificate
    String.clean_certificate(self)
  end

  def clean_certificate!
    self.replace clean_certificate
  end

  alias_method :clean_cert, :clean_certificate
end
