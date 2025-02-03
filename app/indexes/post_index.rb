# frozen_string_literal: true

module PostIndex
  def self.included(base)
    base.document_store.index = {
      settings: {
        index: {
          number_of_shards:   5,
          number_of_replicas: 1,
          max_result_window:  500_000,
        },
      },
      mappings: {
        dynamic:    false,
        properties: {
          created_at:               { type: "date" },
          updated_at:               { type: "date" },
          id:                       { type: "integer" },
          fav:                      { type: "boolean" },
          tag_count:                { type: "integer" },
          change_seq:               { type: "long" },

          tag_count_general:        { type: "integer" },
          tag_count_creator:        { type: "integer" },
          tag_count_character:      { type: "integer" },
          tag_count_copyright:      { type: "integer" },
          tag_count_meta:           { type: "integer" },
          tag_count_species:        { type: "integer" },
          tag_count_invalid:        { type: "integer" },
          tag_count_lore:           { type: "integer" },
          tag_count_fetish:         { type: "integer" },
          tag_count_gender:         { type: "integer" },

          file_size:                { type: "integer" },
          parent:                   { type: "integer" },
          pools:                    { type: "integer" },
          children:                 { type: "integer" },
          width:                    { type: "integer" },
          height:                   { type: "integer" },
          mpixels:                  { type: "float" },
          aspect_ratio:             { type: "float" },
          duration:                 { type: "float" },
          framecount:               { type: "integer" },

          tags:                     { type: "keyword" },
          md5:                      { type: "keyword" },
          rating:                   { type: "keyword" },
          file_ext:                 { type: "keyword" },
          source:                   { type: "keyword" },
          description:              { type: "text" },
          del_reason:               { type: "keyword" },

          deleted:                  { type: "boolean" },
          has_children:             { type: "boolean" },
          has_pending_replacements: { type: "boolean" },
        },
      },
    }

    base.document_store.extend(ClassMethods)
  end

  module ClassMethods
    # Denormalizing the input can be made significantly more
    # efficient when processing large numbers of posts.
    def import(options = {})
      batch_size = options[:batch_size] || 1000

      relation = all
      relation = relation.where("id >= ?", options[:from]) if options[:from]
      relation = relation.where("id <= ?", options[:to])   if options[:to]
      relation = relation.where(options[:query])           if options[:query]

      # PG returns {array,results,like,this}, so we need to parse it
      array_parse = proc do |pid, array|
        [pid, array[1..-2].split(",")]
      end

      relation.find_in_batches(batch_size: batch_size) do |batch| # rubocop:disable Metrics/BlockLength
        post_ids = batch.map(&:id).join(",")

        pools_sql = <<-SQL.squish
          SELECT post_id, ( SELECT COALESCE(array_agg(id), '{}'::int[]) FROM pools WHERE post_ids @> ('{}'::int[] || post_id) )
          FROM (SELECT unnest('{#{post_ids}}'::int[])) as input_list(post_id);
        SQL
        faves_sql = <<-SQL.squish
          SELECT DISTINCT post_id FROM favorites
          WHERE post_id IN (#{post_ids})
        SQL
        child_sql = <<-SQL.squish
          SELECT parent_id, array_agg(id) FROM posts
          WHERE parent_id IN (#{post_ids})
          GROUP BY parent_id
        SQL
        pending_replacements_sql = <<-SQL.squish
          SELECT DISTINCT p.id, CASE WHEN pr.post_id IS NULL THEN false ELSE true END FROM posts p
            LEFT OUTER JOIN post_replacements pr ON p.id = pr.post_id AND pr.status = 'pending'
          WHERE p.id IN (#{post_ids})
        SQL

        # Run queries
        conn = ApplicationRecord.connection
        pool_ids         = conn.execute(pools_sql).values.map(&array_parse).to_h
        fave_ids         = conn.execute(faves_sql).values
        child_ids        = conn.execute(child_sql).values.map(&array_parse).to_h
        pending_replacements = conn.execute(pending_replacements_sql).values.to_h

        empty = []
        batch.map! do |p|
          index_options = {
            pools:                    pool_ids[p.id] || empty,
            fav:                      fave_ids.include?(p.id),
            children:                 child_ids[p.id] || empty,
            del_reason:               p.is_deleted? ? p.deletion_reason : empty,
            has_pending_replacements: pending_replacements[p.id],
          }

          {
            index: {
              _id:  p.id,
              data: p.as_indexed_json(index_options),
            },
          }
        end

        client.bulk({
          index: index_name,
          body:  batch,
        })
      end
    end
  end

  def as_indexed_json(options = {})
    {
      created_at:               created_at,
      updated_at:               updated_at,
      id:                       id,
      fav:                      options.key?(:fav) ? options[:fav] : is_favorited?,
      tag_count:                tag_count,
      change_seq:               change_seq,

      tag_count_general:        tag_count_general,
      tag_count_creator:        tag_count_creator,
      tag_count_character:      tag_count_character,
      tag_count_copyright:      tag_count_copyright,
      tag_count_meta:           tag_count_meta,
      tag_count_species:        tag_count_species,
      tag_count_lore:           tag_count_lore,
      tag_count_invalid:        tag_count_invalid,
      tag_count_fetish:         tag_count_fetish,
      tag_count_gender:         tag_count_gender,

      file_size:                file_size,
      parent:                   parent_id,
      pools:                    options[:pools] || ::Pool.where("? = ANY(post_ids)", id).pluck(:id),
      children:                 options[:children] || ::Post.where(parent_id: id).pluck(:id),
      del_reason:               options[:del_reason] || is_deleted? ? deletion_reason : [],
      width:                    image_width,
      height:                   image_height,
      mpixels:                  image_width && image_height ? (image_width.to_f * image_height / 1_000_000).round(2) : 0.0,
      aspect_ratio:             image_width && image_height ? (image_width.to_f / [image_height, 1].max).round(10) : 1.0,
      duration:                 duration,
      framecount:               framecount,

      tags:                     tag_string.split,
      md5:                      md5,
      rating:                   rating,
      file_ext:                 file_ext,
      source:                   source_array.map(&:downcase),
      description:              description.presence,

      deleted:                  is_deleted,
      has_children:             has_children,
      has_pending_replacements: options.key?(:has_pending_replacements) ? options[:has_pending_replacements] : replacements.pending.any?,
    }
  end
end
