# frozen_string_literal: true

class String
  def self.clean_certificate(str)
    CGI.unescape(str).gsub(/(\n|-+(BEGIN|END)\s+CERTIFICATE-+|\s+)/, '').strip
  end

  def clean_certificate
    String.clean_certificate(self)
  end

  def clean_certificate!
    self.replace clean_certificate
  end

  def cleanup
    dup.gsub!(/\s*(\r?\n\s*|\s+)/, ' ')
  end

  def cleanup!
    gsub!(/\s*(\r?\n\s*|\s+)/, ' ')
    self
  end

  def cleanup_production
    Rails.env.production? \
      ? cleanup
      : self
  end

  alias_method :clean_cert, :clean_certificate
end
