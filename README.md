# pangea-aws

AWS provider bindings for the Pangea infrastructure DSL.

## Overview

Provides 436 typed Terraform resource functions for AWS, covering compute, networking,
storage, database, security, monitoring, IoT, and more. Each resource uses Dry::Struct
validation and compiles to Terraform JSON via terraform-synthesizer. Built on pangea-core.

## Installation

```ruby
gem 'pangea-aws', '~> 0.2'
```

## Usage

```ruby
require 'pangea-aws'

template :my_infra do
  provider :aws do
    region "us-east-1"
  end

  vpc = aws_vpc(:main, { cidr_block: "10.0.0.0/16" })
  aws_subnet(:public, { vpc_id: vpc.id, cidr_block: "10.0.1.0/24" })
end
```

## Development

```bash
nix develop
bundle exec rspec
```

## License

Apache-2.0
