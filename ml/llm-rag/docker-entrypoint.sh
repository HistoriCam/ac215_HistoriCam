#!/bin/bash

echo "Container is running!!!"
echo "Architecture: $(uname -m)"

echo "Environment ready! Virtual environment activated."
echo "Python version: $(python --version)"
echo "UV version: $(uv --version)"

# Activate virtual environment
echo "Activating virtual environment..."
source /.venv/bin/activate

# Keep a shell open
if [ "$#" -gt 0 ]; then
	# If the container was started with a command, run it (this allows docker-compose `command:` to work)
	exec "$@"
else
	# Otherwise, open an interactive shell
	exec /bin/bash
fi