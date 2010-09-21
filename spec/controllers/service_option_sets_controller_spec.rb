require 'spec_helper'

describe ServiceOptionSetsController do

  def mock_service_option_set(stubs={})
    @mock_service_option_set ||= mock_model(ServiceOptionSet, stubs)
  end

  describe "GET index" do
    it "assigns all service_option_sets as @service_option_sets" do
      ServiceOptionSet.stub(:find).with(:all).and_return([mock_service_option_set])
      get :index
      assigns[:service_option_sets].should == [mock_service_option_set]
    end
  end

  describe "GET show" do
    it "assigns the requested service_option_set as @service_option_set" do
      ServiceOptionSet.stub(:find).with("37").and_return(mock_service_option_set)
      get :show, :id => "37"
      assigns[:service_option_set].should equal(mock_service_option_set)
    end
  end

  describe "GET new" do
    it "assigns a new service_option_set as @service_option_set" do
      ServiceOptionSet.stub(:new).and_return(mock_service_option_set)
      get :new
      assigns[:service_option_set].should equal(mock_service_option_set)
    end
  end

  describe "GET edit" do
    it "assigns the requested service_option_set as @service_option_set" do
      ServiceOptionSet.stub(:find).with("37").and_return(mock_service_option_set)
      get :edit, :id => "37"
      assigns[:service_option_set].should equal(mock_service_option_set)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created service_option_set as @service_option_set" do
        ServiceOptionSet.stub(:new).with({'these' => 'params'}).and_return(mock_service_option_set(:save => true))
        post :create, :service_option_set => {:these => 'params'}
        assigns[:service_option_set].should equal(mock_service_option_set)
      end

      it "redirects to the created service_option_set" do
        ServiceOptionSet.stub(:new).and_return(mock_service_option_set(:save => true))
        post :create, :service_option_set => {}
        response.should redirect_to(service_option_sets_url)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved service_option_set as @service_option_set" do
        ServiceOptionSet.stub(:new).with({'these' => 'params'}).and_return(mock_service_option_set(:save => false))
        post :create, :service_option_set => {:these => 'params'}
        assigns[:service_option_set].should equal(mock_service_option_set)
      end

      it "re-renders the 'new' template" do
        ServiceOptionSet.stub(:new).and_return(mock_service_option_set(:save => false))
        post :create, :service_option_set => {}
        response.should render_template('new')
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested service_option_set" do
        ServiceOptionSet.should_receive(:find).with("37").and_return(mock_service_option_set)
        mock_service_option_set.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :service_option_set => {:these => 'params'}
      end

      it "assigns the requested service_option_set as @service_option_set" do
        ServiceOptionSet.stub(:find).and_return(mock_service_option_set(:update_attributes => true))
        put :update, :id => "1"
        assigns[:service_option_set].should equal(mock_service_option_set)
      end

      it "redirects to the service_option_set" do
        ServiceOptionSet.stub(:find).and_return(mock_service_option_set(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(service_option_sets_url)
      end
    end

    describe "with invalid params" do
      it "updates the requested service_option_set" do
        ServiceOptionSet.should_receive(:find).with("37").and_return(mock_service_option_set)
        mock_service_option_set.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :service_option_set => {:these => 'params'}
      end

      it "assigns the service_option_set as @service_option_set" do
        ServiceOptionSet.stub(:find).and_return(mock_service_option_set(:update_attributes => false))
        put :update, :id => "1"
        assigns[:service_option_set].should equal(mock_service_option_set)
      end

      it "re-renders the 'edit' template" do
        ServiceOptionSet.stub(:find).and_return(mock_service_option_set(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end
    end

  end

  describe "DELETE destroy" do
    it "destroys the requested service_option_set" do
      ServiceOptionSet.should_receive(:find).with("37").and_return(mock_service_option_set)
      mock_service_option_set.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the service_option_sets list" do
      ServiceOptionSet.stub(:find).and_return(mock_service_option_set(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(service_option_sets_url)
    end
  end

end
