class CutoffScore < ActiveRecord::Base
  
  belongs_to  :test_sequence
  belongs_to  :test_template
  
  validates_presence_of   :test_sequence_id
  validates_numericality_of   :score, :allow_nil=> :true
  
  def description
    if test_template_id.blank?
      description = TestSequence.find(subsequence_id).name
    else
      description = TestTemplate.find(test_template_id).name
    end
  end
  
  def display_seq_position
    display_seq_position = seq_position/10
  end
  
  def position_description
    position_description = display_seq_position.to_s + ' - ' + description
  end
  
  def validate
    if test_template_id.blank? and subsequence_id.blank?
      errors.add_to_base("Test field and Sequence Field cannot both be empty.")
    end
    if not test_template_id.blank? and not subsequence_id.blank?
      errors.add_to_base("only one of the Test field and Sequence Field can be nonempty.")
    end
    if not subsequence_id.blank? and subsequence_id == test_sequence.id
      errors.add_to_base("The subsequence cannot be the same as the test sequence to which this cutoff score belongs.")
    end
    if fail_cutoff_score.blank? and alternate_recommendation.blank?
      errors.add_to_base("If the fail branch is blank then the 'Recommendation if fail' field has to contain a recommendation.")
    end
    if not fail_cutoff_score.blank? 
      if fail_cutoff_score == id
        errors.add_to_base("The fail cutoff score cannot be the same as the cutoff score itself.")
      end
      if not alternate_recommendation.blank?
        errors.add_to_base("The fail recommendation should be blank if the program branches on failure.")
      end
    end
    if pass_cutoff_score.blank? and recommendation.blank?
      errors.add_to_base("If the pass branch is blank then the 'Recommendation if pass' field has to contain a recommendation.")
    end
    if not pass_cutoff_score.blank? 
      if pass_cutoff_score == id
        errors.add_to_base("The pass cutoff score cannot be the same as the cutoff score itself.")
      end
      if not recommendation.blank?
        errors.add_to_base("The pass recommendation should be blank if the program branches on passing.")
      end
    end
    if not pass_cutoff_score.blank? and pass_cutoff_score == id
      errors.add_to_base("The pass cutoff score cannot be the same as the cutoff score itself.")
    end
    if not test_template_id.blank?
      if score.blank?
        errors.add_to_base("Missing score.")
      elsif score > 100 or score < 0
        errors.add_to_base("Score must be non-negative and <= 100")
      end
    elsif not score.blank?
      errors.add_to_base("Score must be blank for Subsequences.")
    end
  end
end