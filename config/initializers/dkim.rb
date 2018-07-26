if defined?(Dkim) && ENV['DKIM_PATH'] && File.exists?(ENV['DKIM_PATH'])
  Dkim::domain      = ENV.fetch('DKIM_DOMAIN') { BetterRecord.app_domain_name }
  Dkim::selector    = `hostname`.strip.to_sym
  Dkim::private_key = File.read(ENV['DKIM_PATH'])
  # This will sign all ActionMailer deliveries
  ActionMailer::Base.register_interceptor(Dkim::Interceptor)
end
