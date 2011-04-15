module SampleSetsHelper
  def naming_element_visibility
    if @sample
      @sample.naming_element_visibility
    else
      @naming_scheme.default_visibilities
    end
  end

  def naming_element_selections
    if @sample
      @sample.naming_element_selections
    else
      nil
    end
  end
end
