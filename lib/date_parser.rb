module DateParser

  def parse_date(year, month, day)
    return Date.today unless year && month && day

    return "#{year}-#{month}-#{day}"
  end

end
