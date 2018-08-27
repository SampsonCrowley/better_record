module BetterRecord
  module InjectMethods
    def self.included(base)
      base.extend self
    end

    def method_missing(method, *args, &block)
      begin
        if BetterRecord.attributes[method.to_sym]
          m = method.to_sym
          self.class.define_method m do
            BetterRecord.__send__ m
          end
          BetterRecord.__send__ m
        else
          raise NoMethodError
        end
      rescue NoMethodError
        super(method, *args, &block)
      end
    end
  end
end
