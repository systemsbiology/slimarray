require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "QualityTrace" do
  fixtures :bioanalyzer_runs, :quality_traces, :samples

  it "should set associated sample references to nil" do
    QualityTrace.find( quality_traces(:quality_trace_00006).id ).destroy
    
    Sample.find( samples(:sample1) ).starting_quality_trace_id.should == nil
  end

end
