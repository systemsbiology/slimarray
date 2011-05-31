module SharedMethods
  # sort attributes numerically so that "12" doesn't come before "2"
  def sort_attributes_numerically(attributes)
    attributes.sort_by{|key| key.first.to_f}
  end
end
