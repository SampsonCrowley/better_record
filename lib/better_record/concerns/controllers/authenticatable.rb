require 'active_support/concern'

module BetterRecord
  module Authenticatable
    extend ActiveSupport::Concern
    include BetterRecord::JWT::ControllerMethods

    included do
      before_action :check_user
    end

    def method_missing(method, *args)
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
        super(method, *args)
      end
    end


  end
end
