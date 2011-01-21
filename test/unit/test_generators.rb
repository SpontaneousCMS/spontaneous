# encoding: UTF-8

require 'test_helper'

# borrowed from Padrino
class GeneratorsTest < Test::Unit::TestCase
  include Spontaneous

  def setup
    @tmp = "#{Dir.tmpdir}/padrino-tests/#{Time.now.to_i}"
    `mkdir -p #{@tmp}`
  end

  def teardown
    conn = Sequel.mysql2(:user => "root")
    %w(pot8o_org pot8o_org_test).each do |db|
      conn.run("DROP DATABASE `#{db}`")
    end
    # `rm -rf #{@tmp}`
  end


  def generate(name, *params)
    "Spontaneous::Generators::#{name.to_s.camelize}".constantize.start(params)
  end

  context "Site generator" do
    should "create a site using passed parameters" do
      puts @tmp
      generate(:site, "pot8o.org", "--root=#{@tmp}")
      %w(pot8o_org pot8o_org_test).each do |db|
        db = Sequel.mysql2(:user => "root", :database => db)
        lambda { db.tables }.should_not raise_error(Sequel::DatabaseConnectionError)
      end
    end
  end
end
