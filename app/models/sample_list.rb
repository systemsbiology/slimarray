class SampleList < ActiveRecord::Base
  has_many :sample_list_samples
  has_many :samples, :through => :sample_list_samples

  def <<(samples)
    SampleListSample.import(
      [:sample_list_id, :sample_id],
      samples.collect {|s| [self.id, s.id]}
    )
  end
end
