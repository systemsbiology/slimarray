require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe LabelsController do

  before(:each) do
    @labels = mock("Label choices")
  end

  def mock_label(stubs={})
    @mock_label ||= mock_model(Label, stubs)
  end

  describe "GET index" do
    it "assigns all labels as @labels" do
      Label.stub!(:find).with(:all).and_return([mock_label])
      get :index
      assigns[:labels].should == [mock_label]
    end
  end

  describe "GET show" do
    it "assigns the requested label as @label" do
      Label.stub!(:find).with("37").and_return(mock_label)
      get :show, :id => "37"
      assigns[:label].should equal(mock_label)
    end
  end

  describe "GET new" do
    it "assigns a new label as @label" do
      Label.stub!(:new).and_return(mock_label)
      get :new
      assigns[:label].should equal(mock_label)
    end
  end

  describe "GET edit" do
    it "assigns the requested label as @label" do
      Label.should_receive(:find).with("37").and_return(mock_label)
      Label.should_receive(:all).and_return(@labels)
      get :edit, :id => "37"
      assigns[:label].should equal(mock_label)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created label as @label" do
        Label.stub!(:new).with({'these' => 'params'}).and_return(mock_label(:save => true))
        post :create, :label => {:these => 'params'}
        assigns[:label].should equal(mock_label)
      end

      it "redirects to the created label" do
        Label.stub!(:new).and_return(mock_label(:save => true))
        post :create, :label => {}
        response.should redirect_to(labels_url)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved label as @label" do
        Label.stub!(:new).with({'these' => 'params'}).and_return(mock_label(:save => false))
        post :create, :label => {:these => 'params'}
        assigns[:label].should equal(mock_label)
      end

      it "re-renders the 'new' template" do
        Label.stub!(:new).and_return(mock_label(:save => false))
        post :create, :label => {}
        response.should render_template('new')
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested label" do
        Label.should_receive(:find).with("37").and_return(mock_label)
        mock_label.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :label => {:these => 'params'}
      end

      it "assigns the requested label as @label" do
        Label.stub!(:find).and_return(mock_label(:update_attributes => true))
        put :update, :id => "1"
        assigns[:label].should equal(mock_label)
      end

      it "redirects to the label" do
        Label.stub!(:find).and_return(mock_label(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(labels_url)
      end
    end

    describe "with invalid params" do
      it "updates the requested label" do
        Label.should_receive(:find).with("37").and_return(mock_label)
        mock_label.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :label => {:these => 'params'}
      end

      it "assigns the label as @label" do
        Label.stub!(:find).and_return(mock_label(:update_attributes => false))
        put :update, :id => "1"
        assigns[:label].should equal(mock_label)
      end

      it "re-renders the 'edit' template" do
        Label.stub!(:find).and_return(mock_label(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end
    end

  end

  describe "DELETE destroy" do
    it "destroys the requested label" do
      Label.should_receive(:find).with("37").and_return(mock_label)
      mock_label.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the labels list" do
      Label.stub!(:find).and_return(mock_label(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(labels_url)
    end
  end

end
