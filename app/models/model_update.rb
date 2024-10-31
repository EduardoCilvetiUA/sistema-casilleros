class ModelUpdate < ApplicationRecord
    belongs_to :controller
    belongs_to :model
  
    validates :status, presence: true
    validates :started_at, presence: true
  
    enum status: {
      pending: 'pending',
      in_progress: 'in_progress',
      completed: 'completed',
      failed: 'failed'
    }
  end
  