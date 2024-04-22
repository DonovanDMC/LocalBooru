# frozen_string_literal: true

class LockableUserVote < UserVote
  self.abstract_class = true
  validates :score, inclusion: { in: [-1, 1], message: "must be 1 or -1" }

  def self.vote_types
    [%w[Downvote redtext -1], %w[Upvote greentext 1]]
  end

  def self.model_type
    super.to_s.delete_prefix("lockable_").to_sym
  end

  def vote_type
    if is_locked?
      "locked"
    else
      super
    end
  end

  def self.search(params)
    super.attribute_matches(:is_locked, params[:is_locked])
  end

  def vote_display
    return super unless is_locked?
    %{<span class="yellowtext">Locked</span> (#{super})}
  end
end
