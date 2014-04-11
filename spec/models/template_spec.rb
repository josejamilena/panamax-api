require 'spec_helper'

describe Template do
  it { should have_and_belong_to_many(:images) }

  context 'when rendered to json' do
    it 'includes an image count' do
      expect(subject.to_json).to include("\"image_count\":#{subject.images.count}")
    end
  end
end