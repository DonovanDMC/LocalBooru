# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_02_03_220408) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "creator_urls", force: :cascade do |t|
    t.bigint "creator_id", null: false
    t.text "url", null: false
    t.text "normalized_url", null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_creator_urls_on_creator_id"
    t.index ["url", "creator_id"], name: "index_creator_urls_on_url_and_creator_id", unique: true
  end

  create_table "creator_versions", force: :cascade do |t|
    t.bigint "creator_id", null: false
    t.string "name", null: false
    t.inet "updater_ip_addr", null: false
    t.text "urls", default: [], null: false, array: true
    t.text "notes", default: "", null: false
    t.boolean "notes_changed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "other_names", default: [], null: false, array: true
    t.index ["creator_id"], name: "index_creator_versions_on_creator_id"
  end

  create_table "creators", force: :cascade do |t|
    t.string "name", null: false
    t.inet "creator_ip_addr", null: false
    t.text "other_names", default: [], null: false, array: true
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "destroyed_posts", force: :cascade do |t|
    t.integer "post_id", null: false
    t.string "md5", null: false
    t.inet "destroyer_ip_addr", null: false
    t.inet "uploader_ip_addr", null: false
    t.datetime "upload_date", precision: nil
    t.json "post_data", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reason", default: "", null: false
    t.boolean "notify", default: true, null: false
  end

  create_table "exception_logs", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "class_name", null: false
    t.inet "ip_addr", null: false
    t.string "version", null: false
    t.text "extra_params", default: "{}", null: false
    t.text "message", null: false
    t.text "trace", null: false
    t.uuid "code", null: false
  end

  create_table "favorites", force: :cascade do |t|
    t.integer "post_id", null: false
    t.datetime "created_at", precision: nil, default: -> { "now()" }, null: false
    t.inet "creator_ip_addr", null: false
    t.index ["post_id"], name: "index_favorites_on_post_id"
  end

  create_table "mod_actions", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "action", null: false
    t.json "values", default: {}, null: false
    t.integer "subject_id"
    t.string "subject_type"
    t.inet "creator_ip_addr", null: false
    t.index ["action"], name: "index_mod_actions_on_action"
  end

  create_table "pool_versions", force: :cascade do |t|
    t.integer "pool_id", null: false
    t.integer "post_ids", default: [], null: false, array: true
    t.integer "added_post_ids", default: [], null: false, array: true
    t.integer "removed_post_ids", default: [], null: false, array: true
    t.inet "updater_ip_addr", null: false
    t.text "description", null: false
    t.boolean "description_changed", default: false, null: false
    t.text "name", default: "", null: false
    t.boolean "name_changed", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "is_active", default: true, null: false
    t.integer "version", default: 1, null: false
    t.index ["pool_id"], name: "index_pool_versions_on_pool_id"
    t.index ["updater_ip_addr"], name: "index_pool_versions_on_updater_ip_addr"
  end

  create_table "pools", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.text "description", default: "", null: false
    t.boolean "is_active", default: true, null: false
    t.integer "post_ids", default: [], null: false, array: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "creator_names", default: [], null: false, array: true
    t.inet "creator_ip_addr", null: false
    t.index "lower((name)::text) gin_trgm_ops", name: "index_pools_on_name_trgm", using: :gin
    t.index "lower((name)::text)", name: "index_pools_on_lower_name"
    t.index ["name"], name: "index_pools_on_name"
    t.index ["updated_at"], name: "index_pools_on_updated_at"
  end

  create_table "post_events", force: :cascade do |t|
    t.bigint "post_id", null: false
    t.integer "action", null: false
    t.jsonb "extra_data", null: false
    t.datetime "created_at", precision: nil, null: false
    t.inet "creator_ip_addr", null: false
    t.index ["post_id"], name: "index_post_events_on_post_id"
  end

  create_table "post_replacements", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "post_id", null: false
    t.inet "creator_ip_addr", null: false
    t.string "file_ext", null: false
    t.integer "file_size", null: false
    t.integer "image_height", null: false
    t.integer "image_width", null: false
    t.string "md5", null: false
    t.string "source", default: "", null: false
    t.string "file_name"
    t.string "storage_id", null: false
    t.string "status", default: "pending", null: false
    t.string "reason", null: false
    t.boolean "protected", default: false, null: false
    t.jsonb "previous_details"
    t.inet "approver_ip_addr"
    t.inet "rejector_ip_addr"
    t.inet "uploader_ip_addr_on_approve"
    t.index ["post_id"], name: "index_post_replacements_on_post_id"
  end

  create_table "post_versions", force: :cascade do |t|
    t.integer "post_id", null: false
    t.text "tags", null: false
    t.text "added_tags", default: [], null: false, array: true
    t.text "removed_tags", default: [], null: false, array: true
    t.inet "updater_ip_addr", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "rating", limit: 1, null: false
    t.boolean "rating_changed", default: false, null: false
    t.integer "parent_id"
    t.boolean "parent_changed", default: false, null: false
    t.text "source", default: "", null: false
    t.boolean "source_changed", default: false, null: false
    t.text "description", default: "", null: false
    t.boolean "description_changed", default: false, null: false
    t.integer "version", default: 1, null: false
    t.string "reason"
    t.text "original_tags", default: "", null: false
    t.index ["post_id"], name: "index_post_versions_on_post_id"
    t.index ["updated_at"], name: "index_post_versions_on_updated_at"
    t.index ["updater_ip_addr"], name: "index_post_versions_on_updater_ip_addr"
  end

  create_table "posts", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil
    t.string "source", null: false
    t.string "md5", null: false
    t.string "rating", limit: 1, default: "a", null: false
    t.boolean "is_deleted", default: false, null: false
    t.inet "uploader_ip_addr", null: false
    t.text "pool_string", default: "", null: false
    t.text "tag_string", default: "", null: false
    t.integer "tag_count", default: 0, null: false
    t.integer "tag_count_general", default: 0, null: false
    t.integer "tag_count_artist", default: 0, null: false
    t.integer "tag_count_character", default: 0, null: false
    t.integer "tag_count_copyright", default: 0, null: false
    t.string "file_ext", null: false
    t.integer "file_size", null: false
    t.integer "image_width", null: false
    t.integer "image_height", null: false
    t.integer "parent_id"
    t.boolean "has_children", default: false, null: false
    t.boolean "has_active_children", default: false, null: false
    t.bigint "bit_flags", default: 0, null: false
    t.integer "tag_count_meta", default: 0, null: false
    t.integer "tag_count_species", default: 0, null: false
    t.integer "tag_count_invalid", default: 0, null: false
    t.text "description", default: "", null: false
    t.bigserial "change_seq", null: false
    t.integer "tag_count_lore", default: 0, null: false
    t.string "bg_color"
    t.string "generated_samples", array: true
    t.decimal "duration"
    t.text "original_tag_string", default: "", null: false
    t.string "qtags", default: [], null: false, array: true
    t.string "upload_url"
    t.integer "tag_count_gender", default: 0, null: false
    t.integer "framecount"
    t.integer "thumbnail_frame"
    t.string "deletion_reason"
    t.integer "tag_count_creator", default: 0, null: false
    t.integer "tag_count_fetish", default: 0, null: false
    t.index "string_to_array(tag_string, ' '::text)", name: "index_posts_on_string_to_array_tag_string", using: :gin
    t.index ["change_seq"], name: "index_posts_on_change_seq", unique: true
    t.index ["created_at"], name: "index_posts_on_created_at"
    t.index ["md5"], name: "index_posts_on_md5", unique: true
    t.index ["parent_id"], name: "index_posts_on_parent_id"
    t.index ["uploader_ip_addr"], name: "index_posts_on_uploader_ip_addr"
  end

  create_table "tag_aliases", id: :serial, force: :cascade do |t|
    t.string "antecedent_name", null: false
    t.string "consequent_name", null: false
    t.inet "creator_ip_addr", null: false
    t.text "status", default: "pending", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "post_count", default: 0, null: false
    t.string "reason"
    t.inet "approver_ip_addr"
    t.inet "rejector_ip_addr"
    t.index ["antecedent_name"], name: "index_tag_aliases_on_antecedent_name"
    t.index ["antecedent_name"], name: "index_tag_aliases_on_antecedent_name_pattern", opclass: :text_pattern_ops
    t.index ["consequent_name"], name: "index_tag_aliases_on_consequent_name"
    t.index ["post_count"], name: "index_tag_aliases_on_post_count"
  end

  create_table "tag_implications", id: :serial, force: :cascade do |t|
    t.string "antecedent_name", null: false
    t.string "consequent_name", null: false
    t.inet "creator_ip_addr", null: false
    t.text "status", default: "pending", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.text "descendant_names", default: [], array: true
    t.string "reason"
    t.inet "approver_ip_addr"
    t.inet "rejector_ip_addr"
    t.index ["antecedent_name"], name: "index_tag_implications_on_antecedent_name"
    t.index ["consequent_name"], name: "index_tag_implications_on_consequent_name"
  end

  create_table "tag_versions", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "category", null: false
    t.integer "tag_id", null: false
    t.string "reason", default: "", null: false
    t.inet "updater_ip_addr", null: false
    t.index ["tag_id"], name: "index_tag_versions_on_tag_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.integer "post_count", default: 0, null: false
    t.integer "category", limit: 2, default: 0, null: false
    t.text "related_tags"
    t.datetime "related_tags_updated_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index "regexp_replace((name)::text, '([a-z0-9])[a-z0-9'']*($|[^a-z0-9'']+)'::text, '\\1'::text, 'g'::text) gin_trgm_ops", name: "index_tags_on_name_prefix", using: :gin
    t.index ["name"], name: "index_tags_on_name", unique: true
    t.index ["name"], name: "index_tags_on_name_pattern", opclass: :text_pattern_ops
    t.index ["name"], name: "index_tags_on_name_trgm", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "uploads", id: :serial, force: :cascade do |t|
    t.text "source"
    t.string "rating", limit: 1, null: false
    t.inet "uploader_ip_addr", null: false
    t.text "tag_string", null: false
    t.text "status", default: "pending", null: false
    t.text "backtrace"
    t.integer "post_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "parent_id"
    t.string "md5"
    t.string "file_ext"
    t.integer "file_size"
    t.integer "image_width"
    t.integer "image_height"
    t.text "description", default: "", null: false
    t.string "direct_url"
    t.index ["source"], name: "index_uploads_on_source"
    t.index ["uploader_ip_addr"], name: "index_uploads_on_uploader_ip_addr"
  end

  add_foreign_key "creator_urls", "creators"
  add_foreign_key "creator_versions", "creators"
  add_foreign_key "favorites", "posts"
  add_foreign_key "pool_versions", "pools"
  add_foreign_key "post_replacements", "posts"
  add_foreign_key "post_versions", "posts"
  add_foreign_key "tag_versions", "tags"
  add_foreign_key "uploads", "posts"
end
