puts RUBY_VERSION
puts ENV['GEM_HOME']
require File.expand_path('../helper', __FILE__)

class TestGhanaLogger < Test::Unit::TestCase
  should "probably rename this file and start testing for real" do
    flunk "hey buddy, you should probably rename this file and start testing for real"
  end
end
