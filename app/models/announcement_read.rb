# frozen_string_literal: true

# == Schema Information
#
# Table name: announcement_reads
#
#  id              :bigint           not null, primary key
#  read_at         :datetime         not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  announcement_id :bigint           not null
#  contact_id      :bigint           not null
#
# Indexes
#
#  index_announcement_reads_on_announcement_id                 (announcement_id)
#  index_announcement_reads_on_announcement_id_and_contact_id  (announcement_id,contact_id) UNIQUE
#  index_announcement_reads_on_contact_id                      (contact_id)
#
# Foreign Keys
#
#  fk_rails_...  (announcement_id => announcements.id) ON DELETE => cascade
#  fk_rails_...  (contact_id => contacts.id) ON DELETE => cascade
#
class AnnouncementRead < ApplicationRecord
  ## SCOPES
  ## CONCERNS
  ## CONSTANTS
  ## ATTRIBUTES & RELATED
  ## ASSOCIATIONS
  belongs_to :announcement
  belongs_to :contact
  ## VALIDATIONS
  ## CALLBACKS
  ## OTHER

  private

  ## callback methods
end
