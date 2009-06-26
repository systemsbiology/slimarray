class SiteConfig < ActiveRecord::Base
  set_table_name "site_config"

  # This ugly code dynamically creates class methods for SiteConfig per each
  # column in the site_config table. Boolean columns end with a question mark
  class << self
    if(SiteConfig.table_exists?)
      SiteConfig.columns.each do |column|
        if(column.type == :boolean)
          define_method( "#{column.name}?".to_sym ) do
            if(SiteConfig.exists?(1))
              return SiteConfig.find(1).send(column.name)
            end
          end
        else
          define_method( "#{column.name}".to_sym ) do
            if(SiteConfig.exists?(1))
              return SiteConfig.find(1).send(column.name)
            end
          end
        end
      end
    end
  end
  
  def SiteConfig.using_affy_arrays?
    if(SiteConfig.exists?(1))
      if SiteConfig.find(1).array_platform == "affy" ||
         SiteConfig.find(1).array_platform == "both"
        return true
      else
        return false
      end
    end
  end

end
