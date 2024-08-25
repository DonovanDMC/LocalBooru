# frozen_string_literal: true

class ForumPost < ApplicationRecord
  include UserWarnable
  simple_versioning
  mentionable
  attr_readonly :topic_id
  belongs_to_creator counter_cache: "forum_post_count"
  belongs_to_updater
  belongs_to :topic, class_name: "ForumTopic"
  belongs_to :warning_user, class_name: "User", optional: true
  has_many :votes, class_name: "ForumPostVote"
  has_many :tickets, as: :model
  has_many :versions, class_name: "EditHistory", as: :versionable, dependent: :destroy
  has_one :tag_alias
  has_one :tag_implication
  has_one :bulk_update_request
  belongs_to :tag_change_request, polymorphic: true, optional: true
  before_validation :initialize_is_hidden, on: :create
  before_create :auto_report_spam
  after_create :update_topic_updated_at_on_create
  before_destroy :validate_topic_is_unlocked
  after_destroy :update_topic_updated_at_on_destroy
  validates :body, :creator_id, presence: true
  validates :body, length: { minimum: 1, maximum: FemboyFans.config.forum_post_max_size }
  validate :validate_topic_is_unlocked
  validate :validate_topic_id_not_invalid
  validate :validate_topic_is_not_restricted, on: :create
  validate :validate_topic_is_not_stale, on: :create
  validate :validate_category_allows_replies, on: :create
  validate :validate_creator_is_not_limited, on: :create
  validate :validate_not_aibur, if: :will_save_change_to_is_hidden?
  after_save :delete_topic_if_original_post
  after_update(if: ->(rec) { !rec.saved_change_to_is_hidden? && rec.updater_id != rec.creator_id }) do |rec|
    ModAction.log!(:forum_post_update, rec, forum_topic_id: rec.topic_id, user_id: rec.creator_id)
  end
  after_update(if: ->(rec) { rec.saved_change_to_is_hidden? }) do |rec|
    ModAction.log!(rec.is_hidden ? :forum_post_hide : :forum_post_unhide, rec, forum_topic_id: rec.topic_id, user_id: rec.creator_id)
  end
  after_destroy do |rec|
    ModAction.log!(:forum_post_delete, rec, forum_topic_id: rec.topic_id, user_id: rec.creator_id)
  end

  attr_accessor :bypass_limits

  has_dtext_links :body

  module ApiMethods
    def hidden_attributes
      super + %i[notified_mentions]
    end

    def mentions
      notified_mentions.map { |id| { id: id, name: User.id_to_name(id) } }
    end

    def method_attributes
      super + %i[mentions creator_name updater_name]
    end
  end

  module SearchMethods
    def topic_title_matches(title)
      joins(:topic).merge(ForumTopic.search(title_matches: title))
    end

    def for_user(user_id)
      where("forum_posts.creator_id = ?", user_id)
    end

    def visible(user)
      active(user).permitted(user)
    end

    def not_visible(user)
      where.not(id: visible(user))
    end

    def permitted(user)
      q = joins(topic: :category).where("forum_categories.can_view <= ?", user.level)
      q = q.joins(:topic).where("forum_topics.is_hidden = FALSE OR forum_topics.creator_id = ?", user.id) unless user.is_moderator?
      q
    end

    def active(user)
      return all if user.is_moderator?
      where("forum_posts.is_hidden = FALSE OR forum_posts.creator_id = ?", user.id)
    end

    def search(params)
      q = super
      q = q.where_user(:creator_id, :creator, params)

      if params[:topic_id].present?
        q = q.where("forum_posts.topic_id": params[:topic_id])
      end

      if params[:topic_title_matches].present?
        q = q.topic_title_matches(params[:topic_title_matches])
      end

      q = q.attribute_matches(:body, params[:body_matches])

      if params[:topic_category_id].present?
        q = q.joins(:topic).where("forum_topics.category_id": params[:topic_category_id])
      end

      if params[:linked_to].present?
        q = q.linked_to(params[:linked_to])
      end

      if params[:not_linked_to].present?
        q = q.not_linked_to(params[:not_linked_to])
      end

      q = q.attribute_matches(:is_hidden, params[:is_hidden])

      q.apply_basic_order(params)
    end
  end

  include ApiMethods
  extend SearchMethods

  def votable?
    is_aibur?
  end

  def is_aibur?
    tag_change_request.present?
  end

  def validate_topic_is_unlocked
    return if CurrentUser.is_moderator? || topic.nil?

    if topic.is_locked?
      errors.add(:topic, "is locked")
      throw(:abort)
    end
  end

  def validate_creator_is_not_limited
    return if bypass_limits

    allowed = creator.can_forum_post_with_reason
    if allowed != true
      errors.add(:creator, User.throttle_reason(allowed))
      throw(:abort)
    end
  end

  def validate_not_aibur
    return if CurrentUser.is_moderator? || !is_aibur?

    if is_hidden?
      errors.add(:post, "is for an alias, implication, or bulk update request. It cannot be hidden")
      throw(:abort)
    end
  end

  def validate_topic_is_not_stale
    return if !topic&.is_stale_for?(CurrentUser.user) || bypass_limits
    errors.add(:topic, "is stale. New posts cannot be created")
    throw(:abort)
  end

  def validate_topic_id_not_invalid
    if topic_id && !topic
      errors.add(:topic_id, "is invalid")
      throw(:abort)
    end
  end

  def validate_topic_is_not_restricted
    if topic && !topic.visible?(creator)
      errors.add(:topic, "is restricted")
      throw(:abort)
    end
  end

  def validate_category_allows_replies
    if topic && !topic.can_reply?(creator)
      errors.add(:topic, "does not allow replies")
      throw(:abort)
    end
  end

  def editable_by?(user)
    return true if user.is_admin?
    return false if was_warned? || (is_aibur? && !tag_change_request.is_pending?)
    creator_id == user.id && visible?(user)
  end

  def visible?(user)
    user.is_moderator? || (topic.visible?(user) && (!is_hidden? || user.id == creator_id))
  end

  def can_hide?(user)
    return true if user.is_moderator?
    return false if is_aibur?
    return false if was_warned?
    user.id == creator_id
  end

  def can_delete?(user)
    user.is_admin?
  end

  def update_topic_updated_at_on_create
    if topic
      # need to do this to bypass the topic's original post from getting touched
      t = Time.now
      ForumTopic.where(id: topic.id).update_all(["updater_id = ?, response_count = response_count + 1, updated_at = ?, last_post_created_at = ?", CurrentUser.id, t, t])
      topic.response_count += 1
    end
  end

  def hide!
    update(is_hidden: true)
    update_topic_updated_at_on_hide
  end

  def unhide!
    update(is_hidden: false)
    update_topic_updated_at_on_hide
  end

  def update_topic_updated_at_on_hide
    max = ForumPost.where(topic_id: topic.id, is_hidden: false).order("updated_at desc").first
    if max
      ForumTopic.where(id: topic.id).update_all(["updated_at = ?, updater_id = ?", max.updated_at, max.updater_id])
    end
  end

  def update_topic_updated_at_on_destroy
    max = ForumPost.where(topic_id: topic.id, is_hidden: false).order("updated_at desc").first
    if max
      ForumTopic.where(id: topic.id).update_all(["response_count = response_count - 1, updated_at = ?, updater_id = ?", max.updated_at, max.updater_id])
    else
      ForumTopic.where(id: topic.id).update_all("response_count = response_count - 1")
    end
    topic.response_count -= 1
  end

  def initialize_is_hidden
    self.is_hidden = false if is_hidden.nil?
  end

  def forum_topic_page
    (ForumPost.where("topic_id = ? and created_at <= ?", topic_id, created_at).count / FemboyFans.config.records_per_page.to_f).ceil
  end

  def is_original_post?(original_post_id = nil)
    if original_post_id
      id == original_post_id
    else
      ForumPost.exists?(["id = ? and id = (select _.id from forum_posts _ where _.topic_id = ? order by _.id asc limit 1)", id, topic_id])
    end
  end

  def delete_topic_if_original_post
    if is_hidden? && is_original_post?
      topic.update_attribute(:is_hidden, true)
    end

    true
  end

  def hidden_at
    return nil unless is_hidden?
    versions.hidden.last&.created_at
  end

  def warned_at
    return nil unless was_warned?
    versions.marked.last&.created_at
  end

  def edited_at
    versions.edited.last&.created_at
  end

  def auto_report_spam
    if SpamDetector.new(self, user_ip: creator_ip_addr.to_s).spam?
      self.is_spam = true
      tickets << Ticket.new(creator: User.system, creator_ip_addr: "127.0.0.1", reason: "Spam.")
    end
  end

  def mark_spam!
    return if is_spam?
    update!(is_spam: true)
    return if spam_ticket.present?
    SpamDetector.new(self, user_ip: creator_ip_addr.to_s).spam!
  end

  def mark_not_spam!
    return unless is_spam?
    update!(is_spam: false)
    return if spam_ticket.blank?
    SpamDetector.new(self, user_ip: creator_ip_addr.to_s).ham!
  end

  def spam_ticket
    tickets.where(creator: User.system, reason: "Spam.").first
  end
end
