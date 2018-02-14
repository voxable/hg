# frozen_string_literal: true

module Hg
  module Helpers
    # ABBY
    # Add SXSW utm params to url
    #
    # @param [String] url
    #
    # @return [String] new_url with utm params
    UTM_PARAMS = 'utm_source=facebook&utm_campaign=abby&utm_medium=bot'.freeze
    def with_sxsw_utm(url)
      if /sxsw.com/ =~ url
        if url.split('?').count == 1
          @new_url = url + "?#{UTM_PARAMS}"
        else
          @new_url = url + "&#{UTM_PARAMS}"
        end
      end
      @new_url ||= url
    end
  end
end
