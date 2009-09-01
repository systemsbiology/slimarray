require 'ar-extensions'

class SampleListSample < ActiveRecord::Base
  belongs_to :sample
  belongs_to :sample_list
end
