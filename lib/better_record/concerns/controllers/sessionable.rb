# frozen_string_literal: true

require 'active_support/concern'

module BetterRecord
  module Sessionable
    extend ActiveSupport::Concern

    included do
      include BetterRecord::JWT::ControllerMethods
      skip_before_action :check_user, raise: false

      def new
        session[:referrer] ||= request.referrer unless use_bearer_token

        if (header_hash = request.headers.to_h.deep_symbolize_keys)[:HTTP_X_SSL_CERT].present?
          create_session_from_certificate(header_hash[:HTTP_X_SSL_CERT])
          return respond_to_login
        end
      end

      def create
        if(user = session_class.__send__(session_authenticate_method, params))
          current_token = create_jwt(user)
          set_user(user)
        end
        return respond_to_login
      end

      private
        def respond_to_login
          respond_to do |format|
            format.json
            format.html do
              return redirect_to (
                (!use_bearer_token && session.delete(:referrer)) ||
                __send__(after_login_path) ||
                root_path
              )
            end
          end
        end
    end
  end
end
