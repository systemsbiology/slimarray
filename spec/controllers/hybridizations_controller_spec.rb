require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HybridizationsController do
  include AuthenticatedSpecHelper

  before(:each) do
    login_as_user
  end

end
