# frozen_string_literal: true

require 'active_support/concern'

module BetterRecord
  module Sessionable
    extend ActiveSupport::Concern
    include BetterRecord::JWT::ControllerMethods

    included do
      skip_before_action :check_user, raise: false
    end

    def new
      session[:referrer] ||= request.referrer
      p session[:referrer], request.referrer
      if (header_hash = request.headers.to_h.deep_symbolize_keys)[:HTTP_X_SSL_CERT].present?
        create_session_from_certificate(header_hash[:HTTP_X_SSL_CERT])
        redirect_to (session.delete(:referrer) || __send__(after_login_path) || root_path)
      end
    end

    def create
      if(user = session_class.__send__(session_authenticate_method, params))
        session[:better_record] = create_jwt(user)
      end
      respond_to do |format|
        format.json
        format.html do
          return redirect_to (session.delete(:referrer) || __send__(after_login_path) || root_path)
        end
      end
    end
  end
end
