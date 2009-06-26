# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090507170104) do

  create_table "bioanalyzer_runs", :force => true do |t|
    t.string   "name",         :limit => 100
    t.date     "date"
    t.integer  "lock_version",                :default => 0
    t.string   "pdf_path"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "charge_periods", :force => true do |t|
    t.string   "name",         :limit => 50
    t.integer  "lock_version",               :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "charge_sets", :force => true do |t|
    t.integer  "lab_group_id"
    t.integer  "charge_period_id"
    t.string   "name",             :limit => 50
    t.string   "budget_manager",   :limit => 50
    t.string   "budget",           :limit => 100
    t.string   "charge_method",    :limit => 20
    t.integer  "lock_version",                    :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "charge_sets", ["charge_period_id"], :name => "charge_period_id"
  add_index "charge_sets", ["charge_period_id"], :name => "index_charge_sets_on_charge_period_id"
  add_index "charge_sets", ["lab_group_id"], :name => "index_charge_sets_on_lab_group_id"
  add_index "charge_sets", ["lab_group_id"], :name => "lab_group_id"

  create_table "charge_templates", :force => true do |t|
    t.string   "name",               :limit => 40
    t.string   "description",        :limit => 100
    t.integer  "chips_used"
    t.float    "chip_cost"
    t.float    "labeling_cost"
    t.float    "hybridization_cost"
    t.float    "qc_cost"
    t.float    "other_cost"
    t.integer  "lock_version",                      :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "charges", :force => true do |t|
    t.integer  "charge_set_id"
    t.date     "date"
    t.string   "description",        :limit => 100
    t.integer  "chips_used"
    t.float    "chip_cost"
    t.float    "labeling_cost"
    t.float    "hybridization_cost"
    t.float    "qc_cost"
    t.float    "other_cost"
    t.integer  "lock_version",                      :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "charges", ["charge_set_id"], :name => "charge_set_id"
  add_index "charges", ["charge_set_id"], :name => "index_charges_on_charge_set_id"

  create_table "chip_transactions", :force => true do |t|
    t.integer  "lab_group_id",              :default => 0, :null => false
    t.integer  "chip_type_id",              :default => 0, :null => false
    t.date     "date",                                     :null => false
    t.string   "description"
    t.integer  "acquired",     :limit => 8
    t.integer  "used",         :limit => 8
    t.integer  "traded_sold",  :limit => 8
    t.integer  "borrowed_in",  :limit => 8
    t.integer  "returned_out", :limit => 8
    t.integer  "borrowed_out", :limit => 8
    t.integer  "returned_in",  :limit => 8
    t.integer  "lock_version",              :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "chip_types", :force => true do |t|
    t.string   "name",            :limit => 250, :default => "", :null => false
    t.string   "short_name",      :limit => 100, :default => "", :null => false
    t.integer  "organism_id",                    :default => 0,  :null => false
    t.integer  "lock_version",                   :default => 0
    t.string   "array_platform",  :limit => 50
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "library_package"
  end

  create_table "hybridizations", :force => true do |t|
    t.date     "hybridization_date"
    t.integer  "chip_number"
    t.integer  "charge_template_id"
    t.integer  "lock_version",       :default => 0
    t.integer  "sample_id"
    t.integer  "charge_set_id"
    t.text     "raw_data_path"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "hybridizations", ["charge_set_id"], :name => "index_hybridizations_on_charge_set_id"
  add_index "hybridizations", ["charge_template_id"], :name => "index_hybridizations_on_charge_template_id"
  add_index "hybridizations", ["sample_id"], :name => "index_hybridizations_on_sample_id"

  create_table "inventory_checks", :force => true do |t|
    t.date     "date",                           :null => false
    t.integer  "lab_group_id"
    t.integer  "chip_type_id"
    t.integer  "number_expected"
    t.integer  "number_counted"
    t.integer  "lock_version",    :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lab_group_profiles", :force => true do |t|
    t.integer  "lab_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lab_groups", :force => true do |t|
    t.string   "name",         :limit => 250, :default => "", :null => false
    t.integer  "lock_version",                :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lab_memberships", :force => true do |t|
    t.integer  "lab_group_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "naming_elements", :force => true do |t|
    t.string   "name",                          :limit => 100
    t.integer  "element_order"
    t.boolean  "group_element"
    t.boolean  "optional"
    t.integer  "dependent_element_id"
    t.integer  "naming_scheme_id"
    t.integer  "lock_version",                                 :default => 0
    t.boolean  "free_text"
    t.boolean  "include_in_sample_description",                :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "naming_elements", ["dependent_element_id"], :name => "index_naming_elements_on_dependent_element_id"
  add_index "naming_elements", ["naming_scheme_id"], :name => "index_naming_elements_on_naming_scheme_id"

  create_table "naming_schemes", :force => true do |t|
    t.string   "name",         :limit => 100
    t.integer  "lock_version",                :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "naming_terms", :force => true do |t|
    t.string   "term",              :limit => 100
    t.string   "abbreviated_term",  :limit => 20
    t.integer  "naming_element_id"
    t.integer  "lock_version",                     :default => 0
    t.integer  "term_order"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "naming_terms", ["naming_element_id"], :name => "index_naming_terms_on_naming_element_id"

  create_table "organisms", :force => true do |t|
    t.string   "name",         :limit => 50
    t.integer  "lock_version",               :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "projects", :force => true do |t|
    t.string   "name",         :limit => 250
    t.string   "budget",       :limit => 100
    t.integer  "lab_group_id"
    t.integer  "lock_version",                :default => 0
    t.boolean  "active",                      :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "projects", ["lab_group_id"], :name => "index_projects_on_lab_group_id"

  create_table "quality_traces", :force => true do |t|
    t.string   "image_path",         :limit => 200
    t.string   "quality_rating",     :limit => 20
    t.string   "name",               :limit => 100
    t.integer  "number"
    t.string   "sample_type",        :limit => 20
    t.string   "concentration",      :limit => 20
    t.string   "ribosomal_ratio",    :limit => 20
    t.integer  "bioanalyzer_run_id"
    t.integer  "lab_group_id"
    t.integer  "lock_version",                      :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sample_terms", :force => true do |t|
    t.integer  "term_order"
    t.integer  "sample_id"
    t.integer  "naming_term_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sample_terms", ["naming_term_id"], :name => "index_sample_terms_on_naming_term_id"
  add_index "sample_terms", ["sample_id"], :name => "index_sample_terms_on_sample_id"

  create_table "sample_texts", :force => true do |t|
    t.string   "text"
    t.integer  "lock_version",      :default => 0
    t.integer  "sample_id"
    t.integer  "naming_element_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sample_texts", ["naming_element_id"], :name => "index_sample_texts_on_naming_element_id"
  add_index "sample_texts", ["sample_id"], :name => "index_sample_texts_on_sample_id"

  create_table "samples", :force => true do |t|
    t.date     "submission_date"
    t.string   "short_sample_name",           :limit => 20
    t.string   "sample_name",                 :limit => 48
    t.string   "sample_group_name",           :limit => 50
    t.integer  "chip_type_id"
    t.integer  "organism_id"
    t.string   "sbeams_user",                 :limit => 20
    t.string   "status",                      :limit => 50
    t.integer  "lock_version",                              :default => 0
    t.integer  "project_id"
    t.integer  "starting_quality_trace_id"
    t.integer  "amplified_quality_trace_id"
    t.integer  "fragmented_quality_trace_id"
    t.integer  "naming_scheme_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "samples", ["amplified_quality_trace_id"], :name => "index_samples_on_amplified_quality_trace_id"
  add_index "samples", ["chip_type_id"], :name => "index_samples_on_chip_type_id"
  add_index "samples", ["fragmented_quality_trace_id"], :name => "index_samples_on_fragmented_quality_trace_id"
  add_index "samples", ["organism_id"], :name => "index_samples_on_organism_id"
  add_index "samples", ["project_id"], :name => "index_samples_on_project_id"
  add_index "samples", ["starting_quality_trace_id"], :name => "index_samples_on_starting_quality_trace_id"

  create_table "site_config", :force => true do |t|
    t.string   "site_name",             :limit => 50
    t.string   "organization_name",     :limit => 100
    t.string   "facility_name",         :limit => 100
    t.string   "array_platform",        :limit => 20
    t.boolean  "track_inventory"
    t.boolean  "track_hybridizations"
    t.boolean  "track_charges"
    t.boolean  "create_gcos_files"
    t.boolean  "using_sbeams"
    t.string   "gcos_output_path",      :limit => 250
    t.boolean  "use_LDAP"
    t.string   "LDAP_server",           :limit => 200
    t.string   "LDAP_DN",               :limit => 200
    t.integer  "lock_version",                         :default => 0
    t.string   "administrator_email",   :limit => 100
    t.string   "bioanalyzer_pickup",    :limit => 250
    t.string   "quality_trace_dropoff", :limit => 250
    t.string   "sbeams_address",        :limit => 200
    t.string   "raw_data_root_path",    :limit => 200
    t.string   "site_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "agcc_output_path",                     :default => "/tmp"
    t.boolean  "create_agcc_files",                    :default => false
  end

  create_table "user_profiles", :force => true do |t|
    t.integer  "user_id"
    t.string   "role",                     :default => "customer"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "current_naming_scheme_id"
  end

  create_table "users", :force => true do |t|
    t.string   "login",                     :limit => 80, :default => "",         :null => false
    t.string   "crypted_password",          :limit => 40, :default => "",         :null => false
    t.string   "email",                     :limit => 60, :default => "",         :null => false
    t.string   "firstname",                 :limit => 40
    t.string   "lastname",                  :limit => 40
    t.string   "salt",                      :limit => 40, :default => "",         :null => false
    t.string   "role",                      :limit => 40
    t.string   "remember_token",            :limit => 40
    t.datetime "remember_token_expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "current_naming_scheme_id"
    t.string   "name",                                    :default => "customer"
  end

end
