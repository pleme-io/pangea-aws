# frozen_string_literal: true

# Shared examples for all AWS resource synthesis tests.
# Include these in individual resource specs to ensure consistent testing.

RSpec.shared_examples 'a synthesizable resource' do |resource_type, valid_attributes|
  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes without error' do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      send(resource_type, :test, valid_attributes)
    end
    result = synthesizer.synthesis
    expect(result[:resource][resource_type.to_sym][:test]).to be_a(Hash)
  end

  it 'returns a ResourceReference' do
    ref = synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      send(resource_type, :test, valid_attributes)
    end
    expect(ref).to be_a(Pangea::Resources::ResourceReference)
    expect(ref.type).to eq(resource_type.to_s)
    expect(ref.name).to eq(:test)
  end

  it 'has outputs with interpolation strings' do
    ref = synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      send(resource_type, :test, valid_attributes)
    end
    ref.outputs.each_value do |output|
      expect(output).to match(/\$\{#{resource_type}\.test\.\w+\}/)
    end
  end
end

RSpec.shared_examples 'a resource with tags' do |resource_type, valid_attributes|
  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes tags' do
    tagged_attrs = valid_attributes.merge(tags: { Environment: 'test', Team: 'platform' })
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      send(resource_type, :test, tagged_attrs)
    end
    result = synthesizer.synthesis
    config = result[:resource][resource_type.to_sym][:test]
    expect(config[:tags]).to be_a(Hash) if config[:tags]
  end
end

RSpec.shared_examples 'a resource accepting terraform references' do |resource_type, ref_field, base_attributes|
  let(:synthesizer) { TerraformSynthesizer.new }

  it "accepts terraform references in #{ref_field}" do
    ref_attrs = base_attributes.merge(ref_field => '${other.resource.id}')
    expect {
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        send(resource_type, :test, ref_attrs)
      end
    }.not_to raise_error
  end
end
