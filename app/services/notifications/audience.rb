# frozen_string_literal: true

module Notifications
  module Audience
    module_function

    def approved_members
      User.approved
    end

    def approved_admins
      User.admins.approved
    end

    def approved_super_admins
      User.super_admins.approved
    end

    def officers_for_member(member)
      officers = User.officers.approved.where(section_id: member.section_id)
      return approved_super_admins if member.section_id.nil? || officers.none?

      officers
    end
  end
end
