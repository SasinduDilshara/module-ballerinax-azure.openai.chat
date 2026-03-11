# Running Tests

## Prerequisites

You need an API key and endpoint URL from Azure OpenAI.

To obtain these, refer to the [setup guide](https://github.com/ballerina-platform/module-ballerinax-azure.openai.chat/blob/main/ballerina/Module.md#setup-guide).

## Test Environments

There are two test environments for running the `azure.openai.chat` connector tests. The default environment is a mock server for the Azure OpenAI Chat Completions API. The other environment is the actual Azure OpenAI Chat Completions API.

| Test Groups | Environment                                                          |
|-------------|----------------------------------------------------------------------|
| mock_tests  | Mock server for Azure OpenAI Chat Completions API (Default Environment) |
| live_tests  | Azure OpenAI Chat Completions API                                    |

## Running Tests in the Mock Server

To execute the tests on the mock server, ensure that the `isLiveServer` environment variable is either set to `false` or left unset before initiating the tests.

This environment variable can be configured within the `Config.toml` file located in the `tests` directory or specified as an environment variable.

### Using a `Config.toml` File

Create a `Config.toml` file in the `tests` directory with the following content:

```toml
isLiveServer = false
```

### Using Environment Variables

Alternatively, you can set the environment variable directly.

For Linux or macOS:

```bash
export IS_LIVE_SERVER=false
```

For Windows:

```bash
setx IS_LIVE_SERVER false
```

Then, run the following command to execute the tests:

```bash
bal test --groups mock_tests
```

## Running Tests Against the Azure OpenAI Live API

### Using a `Config.toml` File

Create a `Config.toml` file in the `tests` directory and add your authentication credentials:

```toml
isLiveServer = true
token = "<your-azure-openai-api-key>"
serviceUrl = "<your-azure-openai-endpoint-url>"
```

### Using Environment Variables

Alternatively, you can set your authentication credentials as environment variables.

For Linux or macOS:

```bash
export IS_LIVE_SERVER=true
export AZURE_OPENAI_TOKEN="<your-azure-openai-api-key>"
export AZURE_OPENAI_SERVICE_URL="<your-azure-openai-endpoint-url>"
```

For Windows:

```bash
setx IS_LIVE_SERVER true
setx AZURE_OPENAI_TOKEN <your-azure-openai-api-key>
setx AZURE_OPENAI_SERVICE_URL <your-azure-openai-endpoint-url>
```

Then, run the following command to execute the tests:

```bash
bal test --groups live_tests
```
