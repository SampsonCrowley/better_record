# frozen_string_literal: true

module BetterRecord
  class AttachmentValidation < ApplicationRecord
    # == Constants ============================================================

    # == Attributes ===========================================================

    # == Extensions ===========================================================

    # == Relationships ========================================================
    belongs_to :attachment,
      class_name: 'ActiveStorage::Attachment',
      inverse_of: :validations
      
    ActiveStorage::Attachment.has_many :validations,
      class_name: 'BetterRecord::AttachmentValidation',
      foreign_key: :attachment_id,
      inverse_of: :attachment,
      dependent: :destroy
    # == Validations ==========================================================

    # == Scopes ===============================================================

    # == Callbacks ============================================================

    # == Boolean Class Methods ================================================

    # == Class Methods ========================================================

    # == Boolean Methods ======================================================

    # == Instance Methods =====================================================

  end
end
