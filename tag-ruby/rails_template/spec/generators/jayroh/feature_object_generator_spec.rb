# frozen_string_literal: true

require 'generator_spec'
require 'generators/jayroh/feature_object/feature_object_generator'

RSpec.describe Jayroh::FeatureObjectGenerator, type: :generator do
  destination File.expand_path('../../../tmp/generators', __dir__)

  it 'creates a feature object file' do
    prepare_destination

    run_generator %w[home_page step_method_one step_method_two]

    assert_file 'spec/support/feature/home_page.rb'

    expect(destination_root).to(
      have_structure do
        directory 'spec' do
          directory 'support' do
            directory 'feature' do
              file 'home_page.rb' do
                contains 'module Feature'
                contains 'class HomePage'
                contains 'def step_method_one'
                contains 'def step_method_two'
              end
            end
          end
        end
      end
    )
  end
end
