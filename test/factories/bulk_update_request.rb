# frozen_string_literal: true

FactoryBot.define do
  factory(:bulk_update_request) do |_f|
    title { "xxx" }
    script { "create alias aaa -> bbb" }
    reason { "xxxxx" }
  end
end
