require 'digest/md5'

module Spontaneous
  module Model
    module ContentHash
      def digest
        Digest::MD5.new
      end

      def content_hash(*values)
        values = Array(values).flatten
        md5 = digest
        values.each do |value|
          md5.update value.to_s
        end
        md5.hexdigest
      end
    end
  end
end
