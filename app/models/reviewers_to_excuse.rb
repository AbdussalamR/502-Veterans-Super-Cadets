class ReviewersToExcuse < ApplicationRecord
  self.table_name = "reviewers_to_excuse"

  belongs_to :reviewer, class_name: "User", inverse_of: :reviewers_to_excuses
  belongs_to :excuse, inverse_of: :reviewers_to_excuses, optional: true
end