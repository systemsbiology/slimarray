require 'pdf/writer'
require 'pdf/simpletable'
require 'spreadsheet/excel'
include Spreadsheet

class ChargePeriod < ActiveRecord::Base
  has_many :charge_sets, :dependent => :destroy
  
  validates_uniqueness_of :name

  def destroy_warning
    charge_sets = ChargeSet.find(:all, :conditions => ["charge_period_id = ?", id])
    
    return "Destroying this charge period will also destroy:\n" + 
           charge_sets.size.to_s + " charge set(s)\n" +
           "Are you sure you want to destroy it?"
  end

  def to_pdf
    _pdf = PDF::Writer.new()
    _pdf.select_font "Helvetica"
    _pdf.font_size = 16
    _pdf.text "\n\n" + SiteConfig.facility_name + " Charges For Period: " + 
              name + "\n\n", :justification => :center
    
    ###############
    # SUMMARY PAGE
    ###############
        
    table = PDF::SimpleTable.new
    table.width = 536
    table.position = :right
    table.orientation = :left
    table.font_size = 8
    table.heading_font_size = 8
    charge_sets = ChargeSet.find(:all, :conditions => [ "charge_period_id = ?", id ],
		                         :order => "name ASC")
    set_totals = Hash.new(0)
    for set in charge_sets
      totals = set.get_totals
      set_totals['chips'] += totals['chips']
      set_totals['chip_cost'] += totals['chip_cost']
      set_totals['labeling_cost'] += totals['labeling_cost']
      set_totals['hybridization_cost'] += totals['hybridization_cost']
      set_totals['qc_cost'] += totals['qc_cost']
      set_totals['other_cost'] += totals['other_cost']
      set_totals['total_cost'] += totals['total_cost']
      table.data << {"Charge Set" => set.name, "Budget/PO" => set.budget,
                     "Chips" => totals['chips'], "Chip Charge" => fmt_dollars(totals['chip_cost']),
                     "Labeling Charge" => fmt_dollars(totals['labeling_cost']),
                     "Hyb/Wash/Stain/\nScan Charge" => fmt_dollars(totals['hybridization_cost']),
                     "QC Charge" => fmt_dollars(totals['qc_cost']), "Other Charge" => fmt_dollars(totals['other_cost']),
                     "Total Charge" => fmt_dollars(totals['total_cost'])}
    end
    
    # show totals
    table.data << {"Charge Set" => "TOTALS", "Budget/PO" => "",
               "Chips" => set_totals['chips'], "Chip Charge" => fmt_dollars(set_totals['chip_cost']),
               "Labeling Charge" => fmt_dollars(set_totals['labeling_cost']),
               "Hyb/Wash/Stain/\nScan Charge" => fmt_dollars(set_totals['hybridization_cost']),
               "QC Charge" => fmt_dollars(set_totals['qc_cost']), "Other Charge" => fmt_dollars(set_totals['other_cost']),
               "Total Charge" => fmt_dollars(set_totals['total_cost'])}
    
    table.column_order = [ "Charge Set", "Budget/PO", "Chips", "Chip Charge",
                           "Labeling Charge", "Hyb/Wash/Stain/\nScan Charge",
                           "QC Charge", "Other Charge", "Total Charge" ]

    table.columns["Charge Set"] = PDF::SimpleTable::Column.new("Charge Set")
    table.columns["Charge Set"].width = 95
    table.columns["Budget/PO"] = PDF::SimpleTable::Column.new("Budget/PO")
    table.columns["Budget/PO"].width = 55

    RAILS_DEFAULT_LOGGER.error("table before render #{table.inspect}")
    table.render_on(_pdf)
    RAILS_DEFAULT_LOGGER.error("after render")
    
    ############### 
    # DETAIL PAGES
    ###############
    
    for set in charge_sets
      _pdf.start_new_page
      
      # print heading and charge set / project info
      _pdf.font_size = 16
      _pdf.text "\n<b>" + SiteConfig.organization_name + "</b>", :justification => :center
      _pdf.text "<b>" + SiteConfig.facility_name + "</b>\n", :justification => :center

      if FileTest.exists?("public/images/organization_logo.jpg")
        # add logo if one exists
        _pdf.add_image_from_file "public/images/organization_logo.jpg", 450, 685, 120
      end
      
      _pdf.font_size = 10
      _pdf.text "\n\n" +
                "Project: " + set.name
      if set.charge_method == "internal"
        _pdf.text "Org Key: " + set.budget + "\n" +
                  "Budget Manager: " + set.budget_manager + "\n\n" +
                  "Budget Manager Approval: _________________________________"
      else
        _pdf.text "P.O. Number: " + (set.budget || "")
      end
      _pdf.text "\n\n"
      
      # print charge table, if there are any charges
      charges = Charge.find(:all, :conditions => ["charge_set_id = ?", set.id], :order => "date ASC")
      total = 0;
      
      if charges.size > 0
        table = PDF::SimpleTable.new
        table.width = 536
        table.position = :right
        table.orientation = :left
        table.font_size = 8
        table.heading_font_size = 8
        
        for charge in charges
          line_total = charge.chip_cost + charge.labeling_cost + charge.hybridization_cost +
                       charge.qc_cost + charge.other_cost
          total = total + line_total
          table.data << { "Date" => charge.date, "Description" => charge.description[0..49],
                       "Service" => charge.service_name,
                       "Chip\nCharge" => fmt_dollars(charge.chip_cost),
                       "Labeling\nCharge" => fmt_dollars(charge.labeling_cost),
                       "Hyb/Wash/Stain/\nScan Charge" => fmt_dollars(charge.hybridization_cost),
                       "QC\nCharge" => fmt_dollars(charge.qc_cost),
                       "Other\nCharge" => fmt_dollars(charge.other_cost),
                       "Total\nCharge" => fmt_dollars(line_total) }
        end
        table.column_order = [ "Date", "Description", "Service", "Chip\nCharge",
                       "Labeling\nCharge", "Hyb/Wash/Stain/\nScan Charge",
                       "QC\nCharge", "Other\nCharge", "Total\nCharge" ]
        table.columns["Description"] = PDF::SimpleTable::Column.new("Description") { |col|
          col.width = 130
        }

        table.render_on(_pdf)
      end

      _pdf.text "\n\n"
    
      # totals table
      table = PDF::SimpleTable.new
      table.position = :right
      table.orientation = :left
      table.font_size = 8
      table.heading_font_size = 8
      table.data = [ { "name" => "<b>TOTAL</b>", "content" => "<b>" + fmt_dollars(total).to_s + "</b>" }]
      table.column_order = [ "name", "content" ]
      table.columns["name"] = PDF::SimpleTable::Column.new("name") { |col|
        col.width = 60
      }
      table.columns["content"] = PDF::SimpleTable::Column.new("content") { |col|
        col.width = 60
      }  
      table.show_headings = false
      table.shade_rows = :none
      table.render_on(_pdf)

      # instructions
      _pdf.text "\n\n"
      _pdf.text SiteConfig.charge_instructions
    end

    return _pdf
  end

  def to_excel
    puts "VERSION: " + Excel::VERSION
    
    workbook_name = "#{RAILS_ROOT}/tmp/excel/charges_" + name + ".xls"
    workbook = Excel.new(workbook_name)
    # doing each side individually, since :border => 1 is giving an error
    bordered = Format.new( :bottom => 1,
                           :top => 1,
                           :left => 1,
                           :right => 1 )
    bordered_bold = Format.new( :bottom => 1,
                                :top => 1,
                                :left => 1,
                                :right => 1,
                                :bold => true )
    workbook.add_format(bordered)
    workbook.add_format(bordered_bold)
       
    ###############
    # SUMMARY PAGE
    ###############

    summary = workbook.add_worksheet("summary")

    current_row = 0
    summary.write_row current_row+=1, 1, [ "Charge Set", "Budget/PO", "Chips", "Chip Charge",
                              "Labeling Charge", "Hyb/Wash/Stain/\nScan Charge",
                              "QC Cost", "Other Cost", "Total Cost" ], bordered
    charge_sets = ChargeSet.find(:all, :conditions => [ "charge_period_id = ?", id ],
		                         :order => "name ASC")
    set_totals = Hash.new(0)
    for set in charge_sets
      totals = set.get_totals
      set_totals['chips'] += totals['chips']
      set_totals['chip_cost'] += totals['chip_cost']
      set_totals['labeling_cost'] += totals['labeling_cost']
      set_totals['hybridization_cost'] += totals['hybridization_cost']
      set_totals['qc_cost'] += totals['qc_cost']
      set_totals['other_cost'] += totals['other_cost']
      set_totals['total_cost'] += totals['total_cost']
      summary.write_row current_row+=1, 1, [ set.name, set.budget, totals['chips'], fmt_dollars(totals['chip_cost']),
                     fmt_dollars(totals['labeling_cost']), fmt_dollars(totals['hybridization_cost']),
                     fmt_dollars(totals['qc_cost']), fmt_dollars(totals['other_cost']),
                     fmt_dollars(totals['total_cost']) ], bordered
    end
    
    # totals
    summary.write_row current_row+=2, 2, [ "TOTALS", set_totals['chips'],
               fmt_dollars(set_totals['chip_cost']), fmt_dollars(set_totals['labeling_cost']),
               fmt_dollars(set_totals['hybridization_cost']),fmt_dollars(set_totals['qc_cost']),
               fmt_dollars(set_totals['other_cost']), fmt_dollars(set_totals['total_cost']) ], bordered_bold
    
    ############### 
    # DETAIL PAGES
    ###############

    detail = Hash.new(0)
    for set in charge_sets
      detail[set.name] = workbook.add_worksheet(set.name)
      
      # print heading and charge set / project info
      row = 2
      detail[set.name].write row+=1, 1, SiteConfig.organization_name
      detail[set.name].write row+=1, 1, SiteConfig.facility_name

      detail[set.name].write row+=3, 1, "Project: " + set.name
      if set.charge_method == "internal"
        detail[set.name].write row+=1, 1, "Org Key: " + set.budget
        detail[set.name].write row+=1, 1, "Budget Manager: " + set.budget_manager
        detail[set.name].write row+=1, 1, "Budget Manager Approval: _________________________________"
      else
        detail[set.name].write row+=1, 1, "P.O. Number: " + (set.budget || "")
      end
      
      # charge headings
      detail[set.name].write row+=3, 1, [ "Date", "Description", "Service", "Chip Charge",
                     "Labeling Charge", "Hyb/Wash/Stain/\nScan Charge",
                     "QC Cost", "Other Cost", "Sample Total" ], bordered
                     
      # print line item charges      
      charges = Charge.find(:all, :conditions => ["charge_set_id = ?", set.id], :order => "date ASC")     
      total = 0;
      for charge in charges
        line_total = charge.chip_cost + charge.labeling_cost + charge.hybridization_cost +
                     charge.qc_cost + charge.other_cost
        total = total + line_total
        detail[set.name].write row+=1, 1, [ charge.date.to_s, charge.description,
                     charge.service_name, fmt_dollars(charge.chip_cost),
                     fmt_dollars(charge.labeling_cost), fmt_dollars(charge.hybridization_cost),
                     fmt_dollars(charge.qc_cost), fmt_dollars(charge.other_cost),
                     fmt_dollars(line_total) ], bordered
      end
    
      # totals
      detail[set.name].write row+=1, 7, [ "TOTAL", fmt_dollars(total) ], bordered_bold
    end
    workbook.close

    return workbook_name
  end

  private

  def fmt_dollars(amt)
    sprintf("$%0.2f", amt)
  end
end
