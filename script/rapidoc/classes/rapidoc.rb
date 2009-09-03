require 'erb'
require 'fileutils'
require File.dirname(__FILE__) + '/doc_util.rb'
require File.dirname(__FILE__) + '/resource_doc.rb'
# 
class RAPIDoc
  
  # Initalize the ApiDocGenerator
  def initialize(resources)
    puts "Apidoc started..."
    @resources = resources
    generate_templates!
    puts "Finished."
  end
  
  # Iterates over the resources creates views for them.
  # Creates a controller
  # Creates a index file
  def generate_templates!
     
    @resources.each do |r|
      r.parse_apidoc!
      r.generate_view!
    end
    
    generate_controller!
    generate_index!
    
    #make_backups!
    #move_structure!
  end
  
  # takes all resources and writes it to the api controller
  # as methods
  def generate_controller!
    template = ""
    File.open(File.join(File.dirname(__FILE__), '..', 'templates', 'api_controller.rb.erb')).each { |line| template << line }
    parsed = ERB.new(template).result(binding)
    File.open(File.join(File.dirname(__FILE__), '..', 'structure', 'controllers','api_controller.rb'), 'w') { |file| file.write parsed }
  end
  
  # generate the index file for the api controller
  def generate_index!
    template = ""
    File.open(File.join(File.dirname(__FILE__), '..', 'templates', 'index.html.erb.erb')).each { |line| template << line }
    parsed = ERB.new(template).result(binding)
    File.open(File.join(File.dirname(__FILE__), '..', 'structure', 'views', 'apidoc',"index.html.erb"), 'w') { |file| file.write parsed }
  end
  
  # TODO
  def make_backups!
    puts "TODO"
  end
  
  # TODO make this more nice ;p
  def move_structure!
    #to_move = File.dirname(__FILE__) + "/../../"
    app_folder = File.dirname(__FILE__) + "/../../../app/"
    
    c = File.join(File.dirname(__FILE__), '..', "/structure/controllers/api_controller.rb")
    FileUtils.cp(c, app_folder + "/controllers/api_controller.rb")
    
    Dir.new(File.join(File.dirname(__FILE__), '..', '/structure/views/apidoc/')).each do |d|
      if d =~ /^[a-zA-Z]+/
        FileUtils.cp  File.join(File.dirname(__FILE__), '..', '/structure/views/apidoc/' + d), app_folder + 'views/api/' + d
      end
    end
    
  end
  
  
  
  
end