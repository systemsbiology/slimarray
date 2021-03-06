VERBOSE = 0

class BioanalyzerRun < ActiveRecord::Base
  has_many :quality_traces, :dependent => :destroy

  def BioanalyzerRun.import_new
    # not sure why this is necessary, but without it
    # a NameError occurs when trying to do
    # QualityTrace.new below
    require 'quality_trace'
        
    bioanalyzer_pickup_location = SiteConfig.bioanalyzer_pickup
    
    # get a list of the XML and JPG files
    xml_file_pattern = File.join(bioanalyzer_pickup_location,"/*.xml")
    xml_files = Dir.glob(xml_file_pattern)
    jpg_file_pattern = File.join(bioanalyzer_pickup_location,"/*.jpg")
    jpg_files = Dir.glob(jpg_file_pattern)

    # find all the bioanalyzer runs that are already in the database
    existing_runs = BioanalyzerRun.find(:all)
    existing_run_names = Array.new
    for run in existing_runs
      existing_run_names << run.name
    end
    
    for xml_file in xml_files
      puts "Examining XML file: #{xml_file}" if VERBOSE > 0
      
      # name of run is filename minus extension
      run_name = xml_file.scan(/.*\/(.*?)\.xml/i).to_s

      # only process xml files that haven't been loaded yet
      if( !existing_run_names.include?(run_name) )
        # get chip name
        file_root = xml_file.scan(/(.*?)\.xml/i).to_s

        # copy over PDF
        current_pdf_file = "#{file_root}.pdf"
        pdf_path = "#{RAILS_ROOT}/public/quality_traces/#{run_name}.pdf"
        
        # only load runs that have a PDF
        if( File.exists?(current_pdf_file) )
          FileUtils.cp( current_pdf_file, pdf_path)

          # parse XML
          doc = REXML::Document.new( File.new(xml_file) )

          # find who ran the chip
          if(doc.elements["Chipset/Chips/Chip/ChipInformation/UserName"] != nil)
            ran_by = doc.elements["Chipset/Chips/Chip/ChipInformation/UserName"].text
            ran_by_user = User.find(:first, :conditions => {:login => ran_by})
            if(ran_by_user != nil)
              ran_by_email = ran_by_user.email
            end
          end

          # find the chip-wide comments
          chip_comments = doc.elements["Chipset/Chips/Chip/Files/File/FileInformation/Comment"].text
          puts "Chip-wide comments: #{chip_comments}" if VERBOSE > 0

          chip_lab_group = parse_for_lab_group(chip_comments)
          email_recipients = parse_for_emails(chip_comments)

          puts "SLIMarray lab group: #{chip_lab_group}" if VERBOSE > 0
          puts "Email recipients: #{email_recipients}" if VERBOSE > 0

          # create an array to hold traces
          traces = Array.new

          quality_rating = 0
          concentration = 0
          ribosomal_ratio = 0

          # grab each sample-specific node in the XML
          doc.elements.each("Chipset/Chips/Chip/Files/File/Samples/Sample") do |node|
            # only use lanes that have data
            if( node.elements["HasData"].text == "true" )
              number = node.elements["WellNumber"].text

              # figure out sample name and type
              full_name = node.elements["Name"].text
              if( full_name.downcase.match(/(.*)_(total|crna|frag|fragmented).*/) != nil )
                elements = full_name.split(/_/)
                type = elements.pop
                name = elements.join("_")
              elsif( full_name.downcase.match(/(.*)\ (total|crna|frag|fragmented).*/) != nil )
                elements = full_name.split(/ /)
                type = elements.pop
                name = elements.join(" ")
              else
                type = "total"
                name = full_name
              end
              puts "sample full name: #{full_name}" if VERBOSE >= 2

              if(node.elements["DAResultStructures/DARConcentration/Channel/TotalConcentration"] != nil)
                concentration = 
                  node.elements["DAResultStructures/DARConcentration/Channel/TotalConcentration"].text
              end

              # look for sample-specific lab group
              lab_name = node.elements["Comment"].text
              puts "sample-specific lab group: #{lab_name}" if VERBOSE >= 2
              lab_group = nil
              if(lab_name != nil)
                lab_group = LabGroup.find_by_name(lab_name)
              end
              # if there wasn't a spcific lab group specified for this sample,
              # try to use the chip-wide lab group
              if(lab_group == nil)
                lab_group = chip_lab_group
              end

              # need to treat ladder differently
              if( name == "Ladder")
                # associate a jpeg
                current_jpg_file = file_root + "_EGRAM_Ladder.jpg"

                # set type as Ladder
                type = "ladder"
              else
                # associate a jpeg
                current_jpg_file = file_root + "_EGRAM_Sample" + number + ".jpg"

                if(node.elements["DAResultStructures/DARRIN/Channel/RIN"] != nil &&
                   node.elements["DAResultStructures/DARFragment/Channel/rRNARatio"] != nil)
                  quality_rating = node.elements["DAResultStructures/DARRIN/Channel/RIN"].text
                  ribosomal_ratio =
                    node.elements["DAResultStructures/DARFragment/Channel/rRNARatio"].text
                end
              end

              # ensure that sample is tagged with a type, and that image exists
              if( type != nil && lab_group != nil && jpg_files.include?(current_jpg_file) )
                # create new image name, and drop spaces to make the URL easier
                new_image_name = "#{run_name}-#{name}-#{type}.jpg".tr(" ","")
                image_path = "/quality_traces/#{new_image_name}"

                FileUtils.cp( current_jpg_file, "#{RAILS_ROOT}/public#{image_path}")

                # find any existing trace with this name
                existing_traces = QualityTrace.find(:all, :conditions => ["name = ?", name])

                # if there are traces with the same root name, look for repeats
                if( existing_traces.size > 0 )
                  repeat_traces = QualityTrace.find(:all, :conditions => ["name LIKE ?", "%#{name}%_r%"])

                  highest_repeat = 0

                  # find highest repeat number and store it
                  for repeat in repeat_traces
                    repeat_number = repeat.name.scan( /.*_r(.)/ )[0][0].to_i
                    if( repeat_number != nil && repeat_number > highest_repeat )
                      highest_repeat = repeat_number
                    end
                  end

                  name = name + "_r" + (highest_repeat + 1).to_s
                end


                trace = QualityTrace.new(:image_path => image_path,
                  :quality_rating => quality_rating,
                  :name => name,
                  :number => number,
                  :sample_type => type,
                  :concentration => concentration,
                  :ribosomal_ratio => ribosomal_ratio,
                  :lab_group_id => lab_group.id
                )
                traces << trace
              end
            end
          end

          # only save bioanalyzer_run if there are > 1 samples (more than just ladder)
          if( traces.size > 1 )
            # grab the date from the XML
            time_date = doc.elements["Chipset/Chips/Chip/ChipInformation/CreationDate"].text
            date = time_date.scan(/(\d{4}\-\d{2}\-\d{2}).*/).to_s

            run = BioanalyzerRun.new(:name => run_name,
              :date => date, :pdf_path => pdf_path
            )

            # save the traces if the run itself saves
            if( run.save )
              for trace in traces
                trace.bioanalyzer_run_id = run.id
                trace.save
              end

              # only do email notification if a pdf exists
              if( File.exists?(current_pdf_file) )
                Notifier.deliver_bioanalyzer_notification(run, ran_by_email,
                                                          email_recipients)
              end
            end
          end
        end
      end
    end
  end

  def destroy_warning
    quality_traces = QualityTrace.find(:all, :conditions => ["bioanalyzer_run_id = ?", id])
    
    return "Destroying this Bioanalyzer Run will also destroy:\n" + 
      quality_traces.size.to_s + " trace(s)\n" +
      "Are you sure you want to destroy it?"
  end

  def self.find_for_user(user)
    lab_group_ids = user.get_lab_group_ids
  
    # make sure this user belongs to at least one lab group        
    if(lab_group_ids.size > 0)
      # get the traces that the user has access to
      traces = QualityTrace.find( :all, :conditions => ["lab_group_id IN (?)", lab_group_ids] )

      # get unique bioanalyzer run ids from all traces
      bioanalyzer_run_ids = Array.new
      for trace in traces
        if( !bioanalyzer_run_ids.include?(trace.bioanalyzer_run_id) )
          bioanalyzer_run_ids << trace.bioanalyzer_run_id
        end
      end
      bioanalyzer_run_ids.flatten

      if(bioanalyzer_run_ids.size > 0)
        return BioanalyzerRun.find(
          :all,
          :order => "date DESC",
          :conditions => ["id IN (?)", bioanalyzer_run_ids]
        )
      end
    end

    return Array.new
  end

  def to_pdf
    quality_traces = QualityTrace.find( :all, :conditions => ["bioanalyzer_run_id = ?", id],
                                         :order => "number ASC" )

    # create the PDF document  
    _pdf = PDF::Writer.new()

    # print page heading
    _pdf.select_font "Helvetica"
    _pdf.font_size = 16
    _pdf.text "Bioanalyzer Results, page 1\n\n", :justification => :center
    _pdf.font_size = 12
    _pdf.text "Name: " + name + "\n" +
              "Date: " + date.to_s + "\n\n", :justification => :left

    # go to two columns for traces
    _pdf.start_columns(2)
    _pdf.font_size = 10

    # going until size-2 keeps ladder from being shown
    for i in 0..quality_traces.size-2
      # print page heading for new pages
      if(i==6)
        _pdf.stop_columns
        _pdf.start_new_page
            _pdf.select_font "Helvetica"
            _pdf.font_size = 16
            _pdf.text "Bioanalyzer Results, page 2\n\n", :justification => :center
            _pdf.font_size = 12
            _pdf.text "Name: " + name + "\n" +
                      "Date: " + date.to_s + "\n\n", :justification => :left
        _pdf.start_columns(2)
      end
     
      # output trace image
      image_file_path = "#{RAILS_ROOT}/public/" + quality_traces[i].image_path
      _pdf.image image_file_path
      
      # output sample info
      sample_text = "Concentration =" + quality_traces[i].concentration.to_i.to_s + "ng/uL\n"                    
      if( quality_traces[i].sample_type == "total" )
        sample_text += "RIN=" + round_to(quality_traces[i].quality_rating.to_f,2).to_s + "\n" +
                       "28S/18S ratio=" + round_to(quality_traces[i].ribosomal_ratio.to_f,2).to_s + "\n"
      else
        sample_text += "\n\n"
      end

      _pdf.text sample_text, :justification => :center
    end

    return _pdf
  end

private

  def self.parse_for_lab_group(chip_comments)
    if( chip_comments != nil )
      # split on commas, new lines
      names = chip_comments.split(/\s*,\s*|\n/)
      
      names.each do |name|
        chip_lab_group = LabGroup.find_by_name(name)
        if(chip_lab_group != nil)
          return chip_lab_group
        end
      end
    end
    
    return nil
  end
  
  def self.parse_for_emails(chip_comments)  
    if( chip_comments != nil )
      # split on commas, new lines
      names = chip_comments.split(/\s*,\s*|\n/)

      emails = Array.new
      names.each do |name|
        user = User.find(:first, :conditions => {:login => name})
        if(user != nil && user.email != nil)
          emails << user.email
        end
      end

      return emails
    else
      return nil
    end
  end

  def round_to(n,x)
    (n * 10**x).round.to_f / 10**x
  end
end
