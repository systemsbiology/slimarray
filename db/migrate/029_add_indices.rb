class AddIndices < ActiveRecord::Migration
  def self.up
    add_index :samples, :chip_type_id
    add_index :samples, :organism_id
    add_index :samples, :project_id
    add_index :samples, :starting_quality_trace_id
    add_index :samples, :amplified_quality_trace_id
    add_index :samples, :fragmented_quality_trace_id

    add_index :hybridizations, :sample_id
    add_index :hybridizations, :charge_template_id
    add_index :hybridizations, :charge_set_id

    add_index :projects, :lab_group_id

    add_index :charges, :charge_set_id

    add_index :charge_sets, :lab_group_id
    add_index :charge_sets, :charge_period_id

    add_index :naming_elements, :dependent_element_id
    add_index :naming_elements, :naming_scheme_id

    add_index :naming_terms, :naming_element_id

    add_index :sample_terms, :sample_id
    add_index :sample_terms, :naming_term_id

    add_index :sample_texts, :sample_id
    add_index :sample_texts, :naming_element_id
  end

  def self.down
    remove_index :samples, :chip_type_id
    remove_index :samples, :organism_id
    remove_index :samples, :project_id
    remove_index :samples, :starting_quality_trace_id
    remove_index :samples, :amplified_quality_trace_id
    remove_index :samples, :fragmented_quality_trace_id

    remove_index :hybridizations, :sample_id
    remove_index :hybridizations, :charge_template_id
    remove_index :hybridizations, :charge_set_id

    remove_index :projects, :lab_group_id

    remove_index :charges, :charge_set_id

    remove_index :charge_sets, :lab_group_id
    remove_index :charge_sets, :charge_period_id

    remove_index :naming_elements, :dependent_element_id
    remove_index :naming_elements, :naming_scheme_id

    remove_index :naming_terms, :naming_element_id

    remove_index :sample_terms, :sample_id
    remove_index :sample_terms, :naming_term_id

    remove_index :sample_texts, :sample_id
    remove_index :sample_texts, :naming_element_id
  end
end
