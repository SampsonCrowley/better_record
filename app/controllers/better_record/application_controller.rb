module BetterRecord
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    layout BetterRecord.layout_template.presence || 'better_record/application'
  end
end
