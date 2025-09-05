# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Easy LLM CLI is an open-source AI agent compatible with multiple LLM providers (a forked version of Gemini CLI). It supports Gemini, OpenAI, and any custom LLM API that follows OpenAI's format. The project enables querying/editing codebases, generating apps from PDFs/sketches, automating operational tasks, and integrating with tools via MCP servers.

## Development Commands

### Building and Testing

- `npm run preflight` - Complete development workflow (clean, install, format, lint, build, typecheck, test)
- `npm run build` - Build all packages and create distribution bundles
- `npm run build:all` - Build everything including sandbox container
- `npm run test` - Run all tests across workspaces
- `npm run test:ci` - Run CI tests with coverage
- `npm run test:e2e` - Run end-to-end integration tests
- `npm run lint` - Lint all TypeScript files
- `npm run lint:fix` - Fix linting issues automatically
- `npm run format` - Format code with Prettier
- `npm run typecheck` - Run TypeScript type checking

### Development Workflow

- `npm run start` - Start the CLI in development mode
- `npm run debug` - Start CLI with Node.js debugger attached
- `npm run bundle` - Create distribution bundles for npm publishing

### Quick Start

- `npx easy-llm-cli` - Run the CLI directly
- `npm install -g easy-llm-cli` - Install globally, then use `elc` command

### Testing Individual Components

- `npm run test --workspace=packages/cli` - Test CLI package only
- `npm run test --workspace=packages/core` - Test core package only
- `npm run test:integration:sandbox:none` - Run integration tests without sandbox
- `npm run test:integration:sandbox:docker` - Run integration tests with Docker sandbox
- `vitest run path/to/test.test.ts` - Run specific test file

## Architecture Overview

### Package Structure

This is a monorepo with two main packages:

1. **`packages/cli`** - Frontend/UI layer
   - React-based terminal UI using Ink
   - Handles user input, display rendering, and configuration
   - Entry point: `packages/cli/src/gemini.tsx`
   - API interface: `packages/cli/src/api/index.ts` (ElcAgent class)

2. **`packages/core`** - Backend/LLM integration layer
   - LLM API communication and tool execution
   - Tool registry and scheduling
   - Configuration management
   - Entry point: `packages/core/src/index.ts`

### Key Architectural Patterns

#### Multi-LLM Support

- **Custom LLM Integration**: Supports OpenAI-compatible APIs via `packages/core/src/custom_llm/`
- **Environment Configuration**: Uses `CUSTOM_LLM_*` environment variables for custom providers
- **Model Switching**: Can switch between Gemini and custom LLMs without workflow changes

#### Tool System

- **BaseTool Abstraction**: All tools extend `BaseTool<TParams, TResult>` in `packages/core/src/tools/tools.ts`
- **Tool Registry**: Centralized tool registration in `packages/core/src/tools/tool-registry.ts`
- **MCP Integration**: Model Context Protocol support for extensible tools
- **Built-in Tools**: File operations, shell execution, web fetching, git integration

#### Configuration System

- **Hierarchical Config**: User settings → Project settings → CLI arguments
- **Extension System**: Supports MCP servers and tool extensions
- **Sandbox Support**: Docker/Podman containerization for safe tool execution

#### Memory and Context Management

- **Conversation History**: Automatic compression when exceeding token limits
- **File Discovery**: Intelligent file discovery and context building
- **Checkpointing**: Session persistence and recovery

### Critical Development Notes

#### Build Process

- Uses ESBuild for bundling with both ESM and CommonJS output
- Two main bundles: `bundle/gemini.js` (CLI) and `bundle/api.js` (programmatic API)
- Workspace-based building with npm workspaces

#### Testing Strategy

- Unit tests with Vitest
- Integration tests with actual LLM API calls
- Sandbox testing for tool execution safety
- E2E tests for complete user workflows

#### Security Considerations

- **Tool Execution**: All file modifications and shell commands require user confirmation
- **Sandboxing**: Optional Docker/Podman isolation for tool execution
- **API Keys**: Uses environment variables, never committed to code
- **Read-only Mode**: Can be restricted to read-only operations

#### Error Handling

- Comprehensive error reporting with context
- Automatic retry with exponential backoff for API failures
- Graceful degradation when tools are unavailable
- User-friendly error messages with actionable suggestions

### Environment Variables for Development

#### LLM Configuration

- `USE_CUSTOM_LLM=true` - Enable custom LLM provider
- `CUSTOM_LLM_MODEL_NAME` - Model name (e.g., "gpt-4")
- `CUSTOM_LLM_ENDPOINT` - API endpoint URL
- `CUSTOM_LLM_API_KEY` - API authentication key
- `CUSTOM_LLM_TEMPERATURE` - Response temperature (0-1)
- `CUSTOM_LLM_MAX_TOKENS` - Maximum response tokens

#### Debugging

- `DEBUG=1` - Enable debug logging
- `GEMINI_CLI_NO_RELAUNCH` - Disable automatic memory relaunch
- `GEMINI_SANDBOX=docker|podman` - Enable sandbox testing

#### Development Features

- `READ_ONLY=true` - Restrict to read-only operations
- `SYSTEM_PROMPT` - Override default system prompt
- `NO_COLOR` - Disable colored output

### Common Development Patterns

#### Adding New Tools

1. Extend `BaseTool<TParams, TResult>` in `packages/core/src/tools/`
2. Implement required methods: `validateToolParams`, `getDescription`, `shouldConfirmExecute`, `execute`
3. Register tool in the appropriate tool registry
4. Add tests following existing patterns

#### Modifying Configuration

1. Update configuration interfaces in `packages/core/src/config/config.ts`
2. Modify argument parsing in `packages/cli/src/config/config.ts`
3. Update settings management in `packages/cli/src/config/settings.ts`
4. Add migration logic if needed

#### Building for Production

1. Run `npm run preflight` to ensure all checks pass
2. Use `npm run bundle` to create distribution bundles
3. Test with `npm run test:e2e` for complete workflow validation
4. Version management via `npm run release:version`

#### Programmatic API Usage

The project supports programmatic usage via the `ElcAgent` class:

```javascript
import { ElcAgent } from 'easy-llm-cli';

const agent = new ElcAgent({
  model: 'custom-llm-model-name',
  apiKey: 'custom-llm-api-key',
  endpoint: 'custom-llm-endpoint',
  extension: {
    mcpServers: {
      chart: {
        command: 'npx',
        args: ['-y', '@antv/mcp-server-chart'],
        trust: false,
      },
    },
    excludeTools: ['run_shell_command'],
  },
});

const result = await agent.run('Please generate a bar chart for sales data');
```
