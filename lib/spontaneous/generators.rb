# encoding: UTF-8

require 'thor/group'

module Spontaneous
  module Generators
    autoload :Site, "spontaneous/generators/site"
    autoload :Page, "spontaneous/generators/page"
    def self.available
      self.constants.map { |c| self.const_get(c) }.select do |c|
        c.ancestors.include?(Thor::Group)
      end
    end

    class Generator < Thor::Group
      def self.source_root; File.expand_path(File.dirname(__FILE__) + "/generators/#{self.name.demodulize.downcase}"); end

      include Thor::Actions

      class_option :root, :desc => "The root destination", :aliases => '-r', :default => ".",   :type => :string
    end
  end # Generators
end # Spontaneous
