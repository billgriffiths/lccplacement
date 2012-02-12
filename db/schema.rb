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

ActiveRecord::Schema.define(:version => 18) do

  create_table "answer_records", :force => true do |t|
    t.string   "problem"
    t.string   "decoded_answer"
    t.datetime "start_time"
    t.integer  "test_result_id"
    t.integer  "template_version_id"
    t.string   "section"
    t.integer  "choices"
  end

  create_table "cutoff_scores", :force => true do |t|
    t.integer "test_template_id"
    t.float   "score"
    t.string  "recommendation"
    t.string  "alternate_recommendation"
    t.integer "seq_position"
    t.integer "test_sequence_id"
    t.integer "subsequence_id"
    t.integer "fail_cutoff_score"
    t.integer "pass_cutoff_score"
  end

  create_table "procedures", :force => true do |t|
    t.string "name"
    t.text   "text"
    t.string "description"
  end

  create_table "recommendations", :force => true do |t|
    t.string  "key_vector"
    t.text    "rec"
    t.integer "tally"
  end

  create_table "students", :force => true do |t|
    t.string   "student_number"
    t.string   "first_name"
    t.string   "last_name"
    t.date     "birth_date"
    t.string   "test_vector"
    t.datetime "last_date"
  end

  create_table "template_versions", :force => true do |t|
    t.integer "version"
    t.text    "template"
    t.integer "test_template_id"
    t.text    "histogram"
    t.integer "number_scores"
  end

  create_table "test_results", :force => true do |t|
    t.string   "answers"
    t.text     "test_items"
    t.float    "score"
    t.integer  "raw_score"
    t.string   "status"
    t.datetime "start_time"
    t.integer  "student_id"
    t.integer  "template_version_id"
    t.string   "test_session_id"
    t.integer  "cutoff_score_id"
  end

  create_table "test_sequences", :force => true do |t|
    t.string  "name"
    t.string  "description"
    t.text    "initial_recommendation"
    t.integer "start_test_id"
    t.integer "list_position"
  end

  create_table "test_sessions", :force => true do |t|
    t.string   "status"
    t.datetime "start_time"
    t.integer  "student_id"
    t.string   "location"
    t.integer  "test_sequence_id"
    t.integer  "start_test_id"
    t.integer  "parent_session"
    t.integer  "final_test"
    t.float    "final_score"
    t.datetime "processed"
  end

  create_table "test_templates", :force => true do |t|
    t.string  "name"
    t.integer "template_version_id"
    t.string  "description"
    t.string  "color",               :limit => 7
    t.string  "code",                :limit => 4
    t.string  "status",              :limit => 8, :default => "active"
  end

  create_table "users", :force => true do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "user_name"
    t.string "password"
    t.string "role"
    t.string "location"
  end

end
