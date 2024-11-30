class ModelUpdate < ApplicationRecord
  belongs_to :controller
  belongs_to :model
  belongs_to :previous_model, class_name: "Model", optional: true, foreign_key: "previous_model_id"

  enum status: { pending: 0, succeeded: 1, failed: 2 }
end
