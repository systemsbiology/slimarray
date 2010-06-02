require 'spec_helper'

describe QcThresholdsController do

  def mock_qc_threshold(stubs={})
    @mock_qc_threshold ||= mock_model(QcThreshold, stubs)
  end

  describe "GET index" do
    it "assigns all qc_thresholds as @qc_thresholds" do
      QcThreshold.stub(:find).with(:all).and_return([mock_qc_threshold])
      get :index
      assigns[:qc_thresholds].should == [mock_qc_threshold]
    end
  end

  describe "GET show" do
    it "assigns the requested qc_threshold as @qc_threshold" do
      QcThreshold.stub(:find).with("37").and_return(mock_qc_threshold)
      get :show, :id => "37"
      assigns[:qc_threshold].should equal(mock_qc_threshold)
    end
  end

  describe "GET new" do
    it "assigns a new qc_threshold as @qc_threshold" do
      QcThreshold.stub(:new).and_return(mock_qc_threshold)
      get :new
      assigns[:qc_threshold].should equal(mock_qc_threshold)
    end
  end

  describe "GET edit" do
    it "assigns the requested qc_threshold as @qc_threshold" do
      QcThreshold.stub(:find).with("37").and_return(mock_qc_threshold)
      get :edit, :id => "37"
      assigns[:qc_threshold].should equal(mock_qc_threshold)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created qc_threshold as @qc_threshold" do
        QcThreshold.stub(:new).with({'these' => 'params'}).and_return(mock_qc_threshold(:save => true))
        post :create, :qc_threshold => {:these => 'params'}
        assigns[:qc_threshold].should equal(mock_qc_threshold)
      end

      it "redirects to the qc_threshold index" do
        QcThreshold.stub(:new).and_return(mock_qc_threshold(:save => true))
        post :create, :qc_threshold => {}
        response.should redirect_to(qc_thresholds_url)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved qc_threshold as @qc_threshold" do
        QcThreshold.stub(:new).with({'these' => 'params'}).and_return(mock_qc_threshold(:save => false))
        post :create, :qc_threshold => {:these => 'params'}
        assigns[:qc_threshold].should equal(mock_qc_threshold)
      end

      it "re-renders the 'new' template" do
        QcThreshold.stub(:new).and_return(mock_qc_threshold(:save => false))
        post :create, :qc_threshold => {}
        response.should render_template('new')
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested qc_threshold" do
        QcThreshold.should_receive(:find).with("37").and_return(mock_qc_threshold)
        mock_qc_threshold.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :qc_threshold => {:these => 'params'}
      end

      it "assigns the requested qc_threshold as @qc_threshold" do
        QcThreshold.stub(:find).and_return(mock_qc_threshold(:update_attributes => true))
        put :update, :id => "1"
        assigns[:qc_threshold].should equal(mock_qc_threshold)
      end

      it "redirects to the qc_thresholds index" do
        QcThreshold.stub(:find).and_return(mock_qc_threshold(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(qc_thresholds_url)
      end
    end

    describe "with invalid params" do
      it "updates the requested qc_threshold" do
        QcThreshold.should_receive(:find).with("37").and_return(mock_qc_threshold)
        mock_qc_threshold.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :qc_threshold => {:these => 'params'}
      end

      it "assigns the qc_threshold as @qc_threshold" do
        QcThreshold.stub(:find).and_return(mock_qc_threshold(:update_attributes => false))
        put :update, :id => "1"
        assigns[:qc_threshold].should equal(mock_qc_threshold)
      end

      it "re-renders the 'edit' template" do
        QcThreshold.stub(:find).and_return(mock_qc_threshold(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end
    end

  end

  describe "DELETE destroy" do
    it "destroys the requested qc_threshold" do
      QcThreshold.should_receive(:find).with("37").and_return(mock_qc_threshold)
      mock_qc_threshold.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the qc_thresholds list" do
      QcThreshold.stub(:find).and_return(mock_qc_threshold(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(qc_thresholds_url)
    end
  end

end
