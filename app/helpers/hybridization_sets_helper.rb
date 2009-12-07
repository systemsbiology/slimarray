module HybridizationSetsHelper

  def error_messages_for_hybridization_set
    errors = @hybridization_set.array_entry_errors

    if(errors)
      contents = ''
      contents << content_tag(:h2, "Errors in this hybridization set prevented it from being created")
      contents << content_tag(:p, "Plese correct the following problems:")
      contents << content_tag(:ul, errors)

      content_tag(:div, contents, :class => "errorExplanation", :id => "errorExplanation")
    else
      ''
    end
  end

end
