require File.expand_path('../spec_helper', __FILE__)

INTRO = <<NERDS
Space: the final frontier. These are the voyages of the starship Enterprise. Her
five-year mission: to explore strange new worlds, to seek out new life and new
civilizations, to boldly go where no man has gone before.
NERDS

describe PatchLog do

  context 'when creating a new model' do

    let :page do
      Page.create!(:title => 'Star Trek', :body => INTRO)
    end

    it 'should set initial version on create' do
      page.current_version_id.should be_a(Time)
    end

    it 'should not set any prior versions' do
      page.previous_versions.should be_empty
    end

  end

  context 'when updating an existing model' do

    let! :page do
      Page.create!(:title => 'Star Trek', :body => INTRO)
    end
    let!(:initial_version) { page.current_version_id }
    let(:intermediate_intro) do
      INTRO.sub('no man', 'no one')
    end
    let(:new_intro) do
      intermediate_intro.sub('five-year', 'continuing').sub('Her', 'Its')
    end

    let!(:intermediate_version) do
      page.update_attributes!(:body => intermediate_intro)
      page.current_version_id
    end

    before do
      page.update_attributes!(:body => new_intro)
    end

    it 'should expose newest data' do
      page.body.should == new_intro
    end

    it 'should change version' do
      page.current_version_id.should_not == initial_version
    end

    it 'should give list of previous versions' do
      page.previous_versions.should == [intermediate_version, initial_version]
    end

    it 'should allow restoration of previous version' do
      page.restore_version(initial_version).body.should == INTRO
    end

    it 'should allow restoration of intermediate version' do
      page.restore_version(intermediate_version).body.
        should == intermediate_intro
    end

    it 'should mark restored version readonly' do
      page.restore_version(initial_version).should be_readonly
    end

    it 'should throw ArgumentError if bogus version requested' do
      expect { page.restore_version(initial_version - 1) }.
        to raise_error(ArgumentError)
    end

  end

  context 'when updating without changes' do

    let! :page do
      Page.create!(:title => 'Star Trek', :body => INTRO)
    end
    let!(:initial_version) { page.current_version_id }

    before do
      page.save!
    end

    it 'should not change version' do
      page.current_version_id.should == initial_version
    end

    it 'should not save a prior version' do
      page.previous_versions.should be_empty
    end

  end

end
