# Hext - E-Ren Build Tool

Development and testing CLI for the E-Ren Rails application. Manages Docker containers and provides convenient commands for development workflows.

## Installation

```bash
# Clone this repo
git clone git@github.com:your-org/hext.git ~/projects/hext

# Make CLI executable
chmod +x ~/projects/hext/hext

# Add to PATH (optional)
echo 'export PATH="$HOME/projects/hext:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## Requirements

- Docker Desktop
- Python 3.6+
- E-Ren Rails app at `~/projects/e_ren`

## Quick Start

```bash
# Start containers (Rails + Postgres)
hext up

# Run all tests
hext test

# Run specific test file
hext test spec/models/user_spec.rb

# Open shell in Rails container
hext shell

# Stop containers
hext down
```

## Commands

### Container Management

- `hext up` - Start Docker containers (Rails + Postgres)
- `hext down` - Stop Docker containers
- `hext build` - Rebuild Docker image (after Dockerfile changes)
- `hext logs` - Show Rails container logs
- `hext shell` - Open bash shell in Rails container
- `hext server` - Start Rails server on http://localhost:3000

### Testing

```bash
# Run all tests
hext test

# Run directory
hext test spec/models

# Run specific file
hext test spec/models/user_spec.rb

# Run specific line
hext test spec/models/user_spec.rb:42

# Run by example name
hext test --example "increments counter"
hext test -e "auto-confirms"

# Run by tag
hext test --tag focus

# Re-run previously failed tests
hext test prev
hext test failed

# Debug mode (enables binding.pry)
hext test --debug spec/models/user_spec.rb:42
hext test -d spec/models
```

### Utilities

- `hext clean-pry` - Remove all `binding.pry` statements from spec files

## Platform Support

Auto-detects your platform (ARM64 for Apple Silicon, AMD64 for Intel/Windows).

Force specific platform:
```bash
hext up --platform arm64    # Apple Silicon
hext up --platform amd64    # Intel/Windows/Linux
hext build --platform amd64 # Build for teammates on different platforms
```

## Architecture

```
hext/
├── hext                  # CLI script (Python)
├── docker-compose.yml    # Rails + Postgres setup
├── Dockerfile.dev        # Development Docker image
├── dagger_stuff/         # CI/CD automation (future)
└── .hext_test_cache.json # Failed test cache
```

## CI/CD Integration

In GitHub Actions:

```yaml
steps:
  - uses: actions/checkout@v4
    with:
      repository: your-org/hext
      path: hext

  - uses: actions/checkout@v4
    with:
      repository: your-org/e_ren
      path: e_ren

  - name: Run tests
    run: ./hext/hext test
```

## Development

Hext uses Docker Compose with volume mounts, so code changes in your local `e_ren/` directory are immediately reflected in the container. No rebuild needed!

1. `hext up` once
2. Edit code in `e_ren/`
3. `hext test` repeatedly

## Contributing

Hext is separated from infrastructure (`e_ren_infra`) so CI/CD can pull build tools without Terraform configs.

## License

MIT
