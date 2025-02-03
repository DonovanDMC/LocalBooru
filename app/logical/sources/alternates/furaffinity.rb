# frozen_string_literal: true

module Sources
  module Alternates
    class Furaffinity < Base
      IMAGE_TO_CREATOR = %r{d2?\.(?:facdn|furaffinity)\.net/art/([0-9a-zA-Z_.~\-\[\]]+)}
      SUBMISSION_URL = %r{furaffinity\.net/view/(\d+)}

      def force_https?
        true
      end

      def domains
        %w[furaffinity.net facdn.net]
      end

      def parse
        # Add gallery link, parsed from direct link
        if @url =~ IMAGE_TO_CREATOR
          @gallery_url = "https://furaffinity.net/user/#{$1}"
          @direct_url = @url
        end
      end

      def original_url
        # Handle old CDN or old broken CDN
        if %w[d.facdn.net d2.facdn.net].include?(@parsed_url.host)
          @parsed_url.host = "d.furaffinity.net"
        end
        # Convert /full/ submission links to /view/ links
        if @parsed_url.path.start_with?("/full/")
          @parsed_url.path = "/view/#{@parsed_url.path[6..]}"
        end
        # Remove "?upload-successful" query after upload
        if @parsed_url.query == "upload-successful"
          @parsed_url.query = nil
        end
        # Remove comment anchor
        if @parsed_url.fragment&.start_with?("cid:")
          @parsed_url.fragment = nil
        end

        if @parsed_url.host.start_with?("www.")
          @parsed_url.host = @parsed_url.host[4..]
        end

        @url = @parsed_url.to_s
      end
    end
  end
end
