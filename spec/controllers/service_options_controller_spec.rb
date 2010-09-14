require 'spec_helper'

describe ServiceOptionsController do

  def mock_service_option(stubs={})
    @mock_service_option ||= mock_model(ServiceOption, stubs)
  end

  describe "GET index" do
    it "assigns all service_options as @service_options" do
      ServiceOption.stub(:find).with(:all).and_return([mock_service_option])
      get :index
      assigns[:service_options].should == [mock_service_option]
    end
  end

  describe "GET show" do
    it "assigns the requested service_option as @service_option" do
      ServiceOption.stub(:find).with("37").and_return(mock_service_option)
      get :show, :id => "37"
      assigns[:service_option].should equal(mock_service_option)
    end
  end

  describe "GET new" do
    it "assigns a new service_option as @service_option" do
      ServiceOption.stub(:new).and_return(mock_service_option)
      get :new
      assigns[:service_option].should equal(mock_service_option)
    end
  end

  describe "GET edit" do
    it "assigns the requested service_option as @service_option" do
      ServiceOption.stub(:find).with("37").and_return(mock_service_option)
      get :edit, :id => "37"
      assigns[:service_option].should equal(mock_service_option)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created service_option as @service_option" do
        ServiceOption.stub(:new).with({'these' => 'params'}).and_return(mock_service_option(:save => true))
        post :create, :service_option => {:these => 'params'}
        assigns[:service_option].should equal(mock_service_option)
      end

      it "redirects to the created service_option" do
        ServiceOption.stub(:new).and_return(mock_service_option(:save => true))
        post :create, :service_option => {}
        response.should redirect_to(service_option_url(mock_service_option))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved service_option as @service_option" do
        ServiceOption.stub(:new).with({'these' => 'params'}).and_return(mock_service_option(:save => false))
        post :create, :service_option => {:these => 'params'}
        assigns[:service_option].should equal(mock_service_option)
      end

      it "re-renders the 'new' template" do
        ServiceOption.stub(:new).and_return(mock_service_option(:save => false))
        post :create, :service_option => {}
        response.should render_template('new')
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested service_option" do
        ServiceOption.should_receive(:find).with("37").and_return(mock_service_option)
        mock_service_option.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :service_option => {:these => 'params'}
      end

      it "assigns the requested service_option as @service_option" do
        ServiceOption.stub(:find).and_return(mock_service_option(:update_attributes => true))
        put :update, :id => "1"
        assigns[:service_option].should equal(mock_service_option)
      end

      it "redirects to the service_option" do
        ServiceOption.stub(:find).and_return(mock_service_option(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(service_option_url(mock_service_option))
      end
    end

    describe "with invalid params" do
      it "updates the requested service_option" do
        ServiceOption.should_receive(:find).with("37").and_return(mock_service_option)
        mock_service_option.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :service_option => {:these => 'params'}
      end

      it "assigns the service_option as @service_option" do
        ServiceOption.stub(:find).and_return(mock_service_option(:update_attributes => false))
        put :update, :id => "1"
        assigns[:service_option].should equal(mock_service_option)
      end

      it "re-renders the 'edit' template" do
        ServiceOption.stub(:find).and_return(mock_service_option(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end
    end

  end

  describe "DELETE destroy" do
    it "destroys the requested service_option" do
      ServiceOption.should_receive(:find).with("37").and_return(mock_service_option)
      mock_service_option.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the service_options list" do
      ServiceOption.stub(:find).and_return(mock_service_option(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(service_options_url)
    end
  end

end
