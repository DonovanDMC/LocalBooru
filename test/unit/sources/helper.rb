# frozen_string_literal: true

module Sources
  module Helper
    # FIXME: I don't think this should *have* to be done this way, but this is the only way it worked

    module_function

    def alternate_should_work(url, alternate_class, replacement_url)
      should("be handled by the correct strategy") do
        site = ::Sources::Alternates.find(url)
        assert_instance_of(alternate_class, site)
      end

      should("result in the correct URL") do
        site = ::Sources::Alternates.find(url)
        assert_equal(replacement_url, site.original_url)
      end
    end
  end
end
