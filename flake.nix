{
  description = "MCP service flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        python = pkgs.python313;

        mcpMemoryVersion = "11.3.1";

        mcpMemoryService = python.pkgs.buildPythonPackage rec {
          pname = "mcp-memory-service";
          version = mcpMemoryVersion;
          pyproject = true;

          src = pkgs.fetchurl {
            url = "https://files.pythonhosted.org/packages/1b/5a/2f13f00628eb373494e534a121e46eed1300cb8b7d2e04c7a8292effb2ff/mcp_memory_service-${version}.tar.gz";
            hash = "sha256-Xh66opvr+Am6xSdjMMTZjjohvqEf2dPhs0S8JCfRbXo=";
          };

          propagatedBuildInputs = with python.pkgs; [
            aiofiles
            aiohttp
            aiosqlite
            apscheduler
            authlib
            build
            chardet
            click
            cryptography
            fastapi
            httpx
            mcp
            numpy
            psutil
            pydantic
            pydantic-settings
            pyjwt
            pypdf
            pyyaml
            python-dotenv
            python-multipart
            requests
            sqlite-vec
            sse-starlette
            uvicorn
            zeroconf
          ];

          nativeBuildInputs = with python.pkgs; [
            hatchling
            hatch-vcs
          ];

          postPatch = ''
            sed -i 's/"python-semantic-release", //' pyproject.toml
            sed -i 's/, "python-semantic-release"//' pyproject.toml
          '';

          doCheck = false;
          dontCheckRuntimeDeps = true;
        };
      in
      {
        packages = {
          default = mcpMemoryService;
          mcp-memory-service = mcpMemoryService;
        };

        devShells = {
          default = pkgs.mkShell {
            packages = with pkgs; [
              python
              uv
              gcc
              git
              just
            ];

            shellHook = ''
              if [ ! -d ".venv" ]; then
                echo "📦 Creating Python virtual environment..."
                uv venv -p 3.13
                echo "📦 Installing mcp-memory-service..."
                uv pip install "mcp-memory-service==${mcpMemoryVersion}"
                echo "✅ mcp-memory-service installed."
              fi
              source .venv/bin/activate

              echo ""
              echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
              echo "  🎭 Agency Agents Development Shell"
              echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
              echo "  Python: $(python --version 2>&1)"
              echo "  mcp-memory-service: $(python -c 'from importlib.metadata import version; print(version(\"mcp-memory-service\"))' 2>/dev/null || echo 'not installed')"
              echo ""
              echo "  📌 Commands:"
              echo "     memory launch       — Start HTTP + Dashboard (port 8000)"
              echo "     memory server       — Start MCP SSE server (port 8765)"
              echo "     memory --help       — Show all options"
              echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
              echo ""
            '';
          };

          minimal = pkgs.mkShell {
            packages = with pkgs; [
              python
              uv
              git
            ];
          };
        };
      }
    );
}
