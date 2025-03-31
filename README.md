# SSH Connection Manager (s)

A powerful and user-friendly SSH connection manager that simplifies server access and key management.

## Features

- Easy server connection management
- SSH key generation and management
- Template-based configuration
- Port forwarding support
- Connection retry mechanism
- ANSI color-coded output
- Comprehensive error handling

## Installation

```bash
# Clone the repository
git clone https://github.com/groberts/s.git
cd s

# Install
make install
```

## Configuration

The tool uses a configuration file located at `~/.sconfig`. A default configuration will be created on first run:

```bash
# s configuration
KEYPATH=~/.ssh
KEYFILE=id_rsa
```

## Usage

```bash
# Connect to a server
s server-name

# Generate a new SSH key
s keygen

# List available servers
s list

# Add a new server
s add server-name

# Remove a server
s remove server-name

# Show help
s help
```

## Development

### Prerequisites

- Bash 4.0 or higher
- SSH client
- Make

### Running Tests

```bash
make test
```

### Code Style

This project follows the [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html).

## License

BSD License - See LICENSE file for details

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request


