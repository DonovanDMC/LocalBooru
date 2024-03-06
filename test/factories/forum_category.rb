# frozen_string_literal: true

FactoryBot.define do
  factory(:forum_category) do
    sequence(:name) { |n| "forum_category_#{n}" }
  end
end
