# frozen_string_literal: true

module Decidim
  module Admin
    module Abilities
      # Defines the abilities for a user in the admin section. Intended to be
      # used with `cancancan`.
      class AdminAbility < Decidim::Abilities::AdminAbility
        def define_abilities
          super

          can :manage, ParticipatoryProcess
          can :manage, ParticipatoryProcessGroup
          can :manage, ParticipatoryProcessStep
          can :manage, Category
          can :manage, ParticipatoryProcessUserRole
          can [:create, :update, :index, :new, :read], StaticPage

          can [:update_slug, :destroy], [StaticPage, StaticPageForm] do |page|
            !StaticPage.default?(page.slug)
          end

          can [:read, :update], Decidim::Organization do |organization|
            organization == user.organization
          end

          can :manage, Feature
          can :manage, :admin_users
          can :manage, Moderation
          can :manage, Attachment
          can :manage, Scope
          can :manage, ScopeType
          can :manage, Newsletter
          can [:create, :index, :new, :read, :invite], User

          can [:destroy], [User] do |user_to_destroy|
            user != user_to_destroy
          end

          can [:index, :verify, :reject], UserGroup
        end
      end
    end
  end
end
