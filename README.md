# Ballerina Azure OpenAI Chat Completions connector

[![Build](https://github.com/ballerina-platform/module-ballerinax-azure.openai.chat/actions/workflows/ci.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-azure.openai.chat/actions/workflows/ci.yml)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-azure.openai.chat.svg)](https://github.com/ballerina-platform/module-ballerinax-azure.openai.chat/commits/main)
[![GitHub Issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-library/module/azure.openai.chat.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-library/labels/module%2Fazure.openai.chat)

## Overview

[Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/) provides access to OpenAI's powerful language models including GPT-4o, GPT-4, and o-series models through Microsoft Azure's enterprise-grade infrastructure. It combines OpenAI's advanced AI capabilities with Azure's security, compliance, and regional availability features.

The `ballerinax/azure.openai.chat` package offers functionality to connect and interact with the [Chat Completions API](https://learn.microsoft.com/en-us/rest/api/aifoundry/) of the Azure AI Foundry Models Service. The Chat Completions API enables you to build conversational AI applications with features like multi-turn conversations, function/tool calling, structured outputs, and vision capabilities.

## Setup guide

To use the Azure OpenAI Chat Completions Connector, you must have access to an Azure OpenAI resource through a [Microsoft Azure account](https://azure.microsoft.com). If you do not have an Azure account, you can sign up for one [here](https://azure.microsoft.com/en-us/free/).

#### Create an Azure OpenAI resource and obtain the API key

1. Sign in to the [Azure Portal](https://portal.azure.com).

2. Search for "Azure OpenAI" in the top search bar and select **Azure OpenAI** from the results.

3. Click **Create** to create a new Azure OpenAI resource. Fill in the required details such as subscription, resource group, region, and resource name, then click **Review + create** and finally **Create**.

4. Once the resource is deployed, navigate to your Azure OpenAI resource.

5. In the left-hand menu, go to **Resource Management** -> **Keys and Endpoint**.

6. Copy one of the provided keys (Key 1 or Key 2) and the endpoint URL. Store them securely to use in your application.

## Quickstart

To use the `Azure OpenAI Chat Completions` connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

Import the `ballerinax/azure.openai.chat` module.

```ballerina
import ballerinax/azure.openai.chat;
```

### Step 2: Create a new connector instance

Create a `chat:Client` with the obtained API key and your Azure OpenAI resource endpoint.

```ballerina
configurable string token = ?;
configurable string serviceUrl = ?;

final chat:Client azureOpenAIChat = check new ({
    auth: {
        token
    }
}, serviceUrl);
```

### Step 3: Invoke the connector operation

Now, you can utilize available connector operations.

#### Create a chat completion

```ballerina
public function main() returns error? {

    chat:ChatCompletionsBody request = {
        model: "gpt-4o-mini",
        messages: [
            {role: "user", "content": "What is the Ballerina programming language?"}
        ]
    };

    chat:InlineResponse200 response = check azureOpenAIChat->/chat/completions.post(request);
}
```

### Step 4: Run the Ballerina application

```bash
bal run
```

## Examples

The `Azure OpenAI Chat Completions` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-azure.openai.chat/tree/main/examples/), covering the following use cases:

1. [Chat completion](https://github.com/ballerina-platform/module-ballerinax-azure.openai.chat/tree/main/examples/chat-completion) - Create a basic chat completion using the Azure OpenAI Chat Completions API.
2. [Function calling](https://github.com/ballerina-platform/module-ballerinax-azure.openai.chat/tree/main/examples/function-calling) - Use function/tool calling to extend the model's capabilities with custom functions.

## Build from the source

### Setting up the prerequisites

1. Download and install Java SE Development Kit (JDK) version 17. You can download it from either of the following sources:

    * [Oracle JDK](https://www.oracle.com/java/technologies/downloads/)
    * [OpenJDK](https://adoptium.net/)

   > **Note:** After installation, remember to set the `JAVA_HOME` environment variable to the directory where JDK was installed.

2. Download and install [Ballerina Swan Lake](https://ballerina.io/).

3. Download and install [Docker](https://www.docker.com/get-started).

   > **Note**: Ensure that the Docker daemon is running before executing any tests.

4. Export GitHub Personal access token with read package permissions as follows:

    ```bash
    export packageUser=<Username>
    export packagePAT=<Personal access token>
    ```

### Build options

Execute the commands below to build from the source.

1. To build the package:

   ```bash
   ./gradlew clean build
   ```

2. To run the tests:

   ```bash
   ./gradlew clean test
   ```

3. To build without the tests:

   ```bash
   ./gradlew clean build -x test
   ```

4. To run tests against different environments:

   ```bash
   ./gradlew clean test -Pgroups=<Comma separated groups/test cases>
   ```

5. To debug the package with a remote debugger:

   ```bash
   ./gradlew clean build -Pdebug=<port>
   ```

6. To debug with the Ballerina language:

   ```bash
   ./gradlew clean build -PbalJavaDebug=<port>
   ```

7. Publish the generated artifacts to the local Ballerina Central repository:

    ```bash
    ./gradlew clean build -PpublishToLocalCentral=true
    ```

8. Publish the generated artifacts to the Ballerina Central repository:

   ```bash
   ./gradlew clean build -PpublishToCentral=true
   ```

## Contribute to Ballerina

As an open-source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful links

* For more information go to the [`azure.openai.chat` package](https://central.ballerina.io/ballerinax/azure.openai.chat/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
