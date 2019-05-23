# frozen_string_literal: true

require "spec_helper"
require "decidim/core/test/shared_examples/has_contextual_help"

describe "Initiatives", type: :system do
  let(:organization) { create(:organization) }
  let(:base_initiative) do
    create(:initiative, organization: organization)
  end

  before do
    switch_to_host(organization.host)
  end

  context "when there are no initiatives and directly accessing from URL" do
    it_behaves_like "a 404 page" do
      let(:target_path) { decidim_initiatives.initiatives_path }
    end
  end
  
  context "when there are no initiatives and accessing from the homepage" do
    it "the menu link is not shown" do
      visit decidim.root_path

      within ".main-nav" do
        expect(page).to have_no_content("Initiatives")
      end
    end
  end
  
  context "when the initiative does not exist" do
    it_behaves_like "a 404 page" do
      let(:target_path) { decidim_initiatives.initiatives_path(99_999_999) }
    end
  end
  
  context "when there are some initiatives and all are unpublished" do
    before do
      create(:initiative, :unpublished, organization: organization)
      create(:initiative, :published)
    end

    context "and directly accessing from URL" do
      it_behaves_like "a 404 page" do
        let(:target_path) { decidim_initiatives.initiatives_path }
      end
    end

    context "and accessing from the homepage" do
      it "the menu link is not shown" do
        visit decidim.root_path

        within ".main-nav" do
          expect(page).to have_no_content("Initiatives")
        end
      end
    end
  end
  
  context "when there are some published initiatives" do
    let!(:initiative) { base_initiative }
    let!(:unpublished_initiative) do
      create(:initiative, :created, organization: organization)
    end

    before do
      visit decidim_initiatives.initiatives_path
    end

    it_behaves_like "shows contextual help" do
      let(:index_path) { decidim_initiatives.initiatives_path }
      let(:manifest_name) { :initiatives }
    end

    it_behaves_like "editable content for admins"

    context "and accessing from the homepage" do
      it "the menu link is shown" do
        visit decidim.root_path

        within ".main-nav" do
          expect(page).to have_content("Initiatives")
          click_link "Initiatives"
        end

        expect(page).to have_current_path(decidim_initiatives.initiatives_path)
      end
    end

    it "lists all the initiatives" do
      within "#initiatives-count" do
        expect(page).to have_content("1")
      end

      within "#initiatives" do
        expect(page).to have_content(translated(initiative.title, locale: :en))
        expect(page).to have_content(initiative.author_name, count: 1)
        expect(page).not_to have_content(translated(unpublished_initiative.title, locale: :en))
      end
    end

    it "links to the individual initiative page" do
      click_link(translated(initiative.title, locale: :en))
      expect(page).to have_current_path(decidim_initiatives.initiative_path(initiative))
    end
  end
end
