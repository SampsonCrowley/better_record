# frozen_string_literal: true

require 'active_support/concern'

module BetterRecord
  module Authenticatable
    extend ActiveSupport::Concern

    included do
      include BetterRecord::JWT::ControllerMethods
      before_action :check_user
      if use_bearer_token
        after_action :set_auth_header
      end
    end

  end
end
