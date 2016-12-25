# frozen_string_literal: true
module Decidim
  module Comments
    # Some resources will be configured as commentable objects so users can
    # comment on them. The will be able to create conversations between users
    # to discuss or share their thoughts about the resource.
    class Comment < ApplicationRecord
      # Limit the max depth of a comment tree. If C is a comment and R is a reply:
      # C          (depth 0)
      # |--R       (depth 1)
      # |--R       (depth 1)
      #    |--R    (depth 2)
      #       |--R (depth 3)
      MAX_DEPTH = 3

      belongs_to :author, foreign_key: "decidim_author_id", class_name: Decidim::User
      belongs_to :commentable, foreign_key: "decidim_commentable_id", foreign_type: "decidim_commentable_type", polymorphic: true
      has_many :replies, as: :commentable, foreign_key: "decidim_commentable_id", foreign_type: "decidim_commentable_type", class_name: Comment
      has_many :up_votes, -> { where(weight: 1) }, foreign_key: "decidim_comment_id", class_name: CommentVote, dependent: :destroy
      has_many :down_votes, -> { where(weight: -1) }, foreign_key: "decidim_comment_id", class_name: CommentVote, dependent: :destroy
      validates :author, :commentable, :body, presence: true
      validate :commentable_can_have_replies
      validates :depth, numericality: { greater_than_or_equal_to: 0 }
      validates :alignment, inclusion: { in: [0, 1, -1] }
      validate :same_organization

      before_save :compute_depth

      delegate :organization, to: :commentable

      # Public: Define if a comment can have replies or not
      #
      # Returns a bool value to indicate if comment can have replies
      def can_have_replies?
        depth < MAX_DEPTH
      end

      # Public: Check if the user has upvoted the comment
      #
      # Returns a bool value to indicate if the condition is truthy or not
      def up_voted_by?(user)
        up_votes.any? { |vote| vote.author == user }
      end

      # Public: Check if the user has downvoted the comment
      #
      # Returns a bool value to indicate if the condition is truthy or not
      def down_voted_by?(user)
        down_votes.any? { |vote| vote.author == user }
      end

      private

      # Private: Check if commentable can have replies and if not adds
      # a validation error to the model
      def commentable_can_have_replies
        errors.add(:commentable, :cannot_have_replies) if commentable.respond_to?(:can_have_replies?) && !commentable.can_have_replies?
      end

      # Private: Compute comment depth inside the current comment tree
      def compute_depth
        self.depth = commentable.depth + 1 if commentable.respond_to?(:depth)
      end

      def same_organization
        errors.add(:commentable, :invalid) unless author.organization == organization
      end
    end
  end
end
