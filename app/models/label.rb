class Label < ActiveRecord::Base

  def match_label
    if match_label_id
      Label.find(match_label_id)
    else
      self
    end
  end
end
