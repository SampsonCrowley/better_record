module BetterRecord
  class ApplicationController < ActionController::Base
    # == Modules ============================================================

    # == Class Methods ======================================================

    # == Pre/Post Flight Checks =============================================
    protect_from_forgery with: :exception
    layout BetterRecord.layout_template.presence || 'better_record/application'

    # == Actions ============================================================

    # == Cleanup ============================================================

  end
end
