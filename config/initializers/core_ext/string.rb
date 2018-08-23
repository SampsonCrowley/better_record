# frozen_string_literal: true

class String
  def self.clean_certificate(str)
    CGI.unescape(str).gsub(/(\n|-----(BEGIN|END) CERTIFICATE-----)/, '').strip
  end

  def clean_certificate
    clean_certificate(self)
  end

  alias_method :clean_cert, :clean_certificate
end
