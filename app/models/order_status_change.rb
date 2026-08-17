class OrderStatusChange < ApplicationRecord
  belongs_to :order

  validates :estado, presence: true
end
