# pangea-aws

AWS provider resources for the Pangea infrastructure DSL. Provides 448+ typed
Terraform resource functions with Dry::Struct validation and synthesis testing.

Resources are a mix of **auto-generated** (via pangea-forge) and **hand-written**.
Both follow the same patterns. All must have RSpec synthesis tests.

## Structure

```
lib/
  pangea-aws.rb                     # Entry point (requires all resources)
  pangea-aws/version.rb             # VERSION constant
  pangea/
    resources/
      aws.rb                        # Aggregator module (Pangea::Resources::AWS)
      aws_*/                        # 448 resource directories
        resource.rb                 # Public API: def aws_<type>(name, attributes)
        types.rb                    # Dry::Struct attributes class
        types/                      # Optional: nested type definitions
      reference/                    # AWS-specific computed attributes
      types/                        # Shared AWS types (AwsTags, etc.)
      validators/                   # AWS-specific validators
spec/
  resources/
    aws_*/synthesis_spec.rb          # Per-resource synthesis tests
  spec_helper.rb
```

## Resource Function Pattern

Every resource follows this exact pattern:

```ruby
# lib/pangea/resources/aws_<type>/resource.rb
module Pangea
  module Resources
    module AWS
      def aws_<type>(name, attributes = {})
        # 1. Validate via dry-struct
        attrs = Types::<Type>Attributes.new(attributes)

        # 2. Synthesize via terraform-synthesizer
        resource(:aws_<type>, name) do
          name attrs.name if attrs.name
          # ... map attributes to synthesizer block
          if attrs.tags&.any?
            tags do
              attrs.tags.each { |k, v| public_send(k, v) }
            end
          end
        end

        # 3. Return ResourceReference with outputs
        ResourceReference.new(
          type: 'aws_<type>',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_<type>.#{name}.id}",
            arn: "${aws_<type>.#{name}.arn}",
            # ... resource-specific outputs
          }
        )
      end
    end
  end
end
```

## Type Attributes Pattern

```ruby
# lib/pangea/resources/aws_<type>/types.rb
module Pangea
  module Resources
    module AWS
      module Types
        class <Type>Attributes < Pangea::Resources::BaseAttributes
          transform_keys(&:to_sym)

          attribute? :name, Resources::Types::String.optional
          attribute :required_field, Resources::Types::String
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          def self.new(attributes = {})
            attrs = super(attributes)
            # Skip validation for Terraform references
            unless terraform_reference?(attrs.required_field)
              # Custom validation here
            end
            attrs
          end
        end
      end
    end
  end
end
```

## Synthesis Test Pattern

```ruby
# spec/resources/aws_<type>/synthesis_spec.rb
RSpec.describe 'aws_<type>' do
  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes with valid attributes' do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      aws_<type>(:test, { name: 'test', ... })
    end
    result = synthesizer.synthesis
    expect(result[:resource][:aws_<type>][:test]).to be_a(Hash)
  end

  it 'returns ResourceReference with outputs' do
    ref = synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      aws_<type>(:test, { name: 'test', ... })
    end
    expect(ref).to be_a(Pangea::Resources::ResourceReference)
    expect(ref.outputs[:id]).to eq('${aws_<type>.test.id}')
  end
end
```

## Key Rules

1. **Every resource MUST have a synthesis spec** — no untested resources
2. **Terraform references MUST bypass validation** — use `terraform_reference?` guard
3. **Tags are handled via block pattern** — never as flat hash in synthesizer
4. **lifecycle meta-argument** — supported on aws_iam_role, extend to others as needed
5. **Mutually exclusive fields** — validate in `self.new` (name/name_prefix, instance/network_interface)
6. **Resource functions extend synthesizer** — architectures call `synth.extend(Pangea::Resources::AWS)`

## Using in Architectures

```ruby
# In pangea-architectures:
def self.build(synth, config = {})
  synth.extend(Pangea::Resources::AWS) unless synth.respond_to?(:aws_vpc)

  vpc = synth.aws_vpc(:main, { cidr_block: '10.0.0.0/16', tags: { Name: 'main' } })
  subnet = synth.aws_subnet(:public, { vpc_id: vpc.id, cidr_block: '10.0.1.0/24' })
end
```

## Dependencies

- pangea-core ~> 0.2
- terraform-synthesizer ~> 0.0.28
- dry-types ~> 1.7, dry-struct ~> 1.6
- Ruby >= 3.3.0, Apache-2.0
