FactoryBot.define do
  factory(:api_key) do
    sequence(:name) { |n| "api_key_#{n}" }
    association :user, factory: :user
  end
end
