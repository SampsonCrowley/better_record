class Task < ApplicationRecord
  # == Constants ============================================================

  # == Attributes ===========================================================
  #           :id => :integer,
  #        :title => :string,
  #  :description => :string,
  #     :due_date => :date,
  # :developer_id => :integer,
  #   :created_at => :datetime,
  #   :updated_at => :datetime

  # == Extensions ===========================================================

  # == Relationships ========================================================
  belongs_to :developer, inverse_of: :tasks

  # == Validations ==========================================================
  validates :title, presence: true, length: { minimum: 5 }

  validate :future_due_date, if: :due_date_changed?

  # == Scopes ===============================================================

  # == Callbacks ============================================================

  # == Class Methods ========================================================

  # == Instance Methods =====================================================
  def future_due_date
    return true if due_date.blank?
    if due_date < Date.current
      errors.add(:due_date, 'cannot be in the past')
      false
    else
      true
    end
  end
end
