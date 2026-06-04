// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/os;
import ballerina/test;

configurable boolean isLiveServer = os:getEnv("IS_LIVE_SERVER") == "true";
configurable string token = isLiveServer ? os:getEnv("AZURE_OPENAI_TOKEN") : "test";
configurable string apiKey = isLiveServer ? os:getEnv("AZURE_OPENAI_API_KEY") : "test";
configurable string serviceUrl = isLiveServer ? os:getEnv("AZURE_OPENAI_SERVICE_URL") : "http://localhost:9090/openai";
configurable string deploymentId = isLiveServer ? os:getEnv("AZURE_OPENAI_DEPLOYMENT_ID") : "gpt-4o-mini";

final string mockServiceUrl = "http://localhost:9090/openai";
const string apiVersion = "2025-04-01-preview";

// Client authenticated with a bearer token (default for both mock and live runs).
final Client azureOpenAI = check initClient();

isolated function initClient() returns Client|error {
    if isLiveServer {
        return new ({auth: {token}}, serviceUrl);
    }
    return new ({auth: {token}}, mockServiceUrl);
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testSimpleChatCompletion() returns error? {
    createChatCompletionRequest request = {
        messages: [
            {role: "system", "content": "You are a helpful assistant."},
            {role: "user", "content": "This is a test message"}
        ]
    };

    inline_response_200 response = check azureOpenAI->/deployments/[deploymentId]/chat/completions.post(
        request, api\-version = apiVersion);

    createChatCompletionResponse completion = check response.ensureType();
    test:assertTrue(completion.id.length() > 0, "Expected a chat completion id");
    test:assertTrue(completion.model.length() > 0, "Expected a model in the completion response");
    test:assertEquals(completion.'object, "chat.completion");
    test:assertTrue(completion.choices.length() > 0, "Expected at least one completion choice");

    createChatCompletionResponse_choices choice = completion.choices[0];
    test:assertEquals(choice.finish_reason, "stop");
    test:assertEquals(choice.message.role, "assistant");
    test:assertTrue(choice.message.content is string && (<string>choice.message.content).length() > 0,
            "Expected non-empty assistant content");
}

@test:Config {
    groups: ["mock_tests"]
}
isolated function testClientInitWithDefaultServiceUrl() returns error? {
    // Exercises the default `serviceUrl` parameter of the client initializer.
    // No request is made, so this does not reach out to the public Azure host.
    // The `check` guarantees initialization succeeded.
    _ = check new Client({auth: {token: "test"}});
}

@test:Config {
    groups: ["mock_tests"]
}
isolated function testChatCompletionWithApiKeyAuth() returns error? {
    // Exercises the API key authentication branch of the client initialization.
    Client apiKeyClient = check new ({auth: {api\-key: apiKey}}, mockServiceUrl);

    createChatCompletionRequest request = {
        messages: [{role: "user", "content": "Ping"}]
    };

    inline_response_200 response = check apiKeyClient->/deployments/[deploymentId]/chat/completions.post(
        request, api\-version = apiVersion);

    createChatCompletionResponse completion = check response.ensureType();
    test:assertEquals(completion.choices.length(), 1);
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testChatCompletionWithOptionalParams() returns error? {
    // Validates the nullable-field fix: temperature, max_tokens, presence_penalty
    // and frequency_penalty must accept both concrete values and `()`.
    createChatCompletionRequest request = {
        messages: [{role: "user", "content": "Tell me a joke"}],
        temperature: 0.7,
        top_p: 0.9,
        max_tokens: 256,
        presence_penalty: 0.5,
        frequency_penalty: 0.5,
        stop: ["\n"],
        user: "test-user-1234"
    };

    inline_response_200 response = check azureOpenAI->/deployments/[deploymentId]/chat/completions.post(
        request, api\-version = apiVersion);

    createChatCompletionResponse completion = check response.ensureType();
    test:assertEquals(completion.choices[0].finish_reason, "stop");
}

@test:Config {
    groups: ["mock_tests"]
}
isolated function testChatCompletionWithNullableFieldsAsNil() returns error? {
    // The whole point of the sanitation: these fields are now `T?` and accept nil.
    createChatCompletionRequest request = {
        messages: [{role: "user", "content": "Hello"}],
        temperature: (),
        top_p: (),
        max_tokens: (),
        presence_penalty: (),
        frequency_penalty: (),
        logit_bias: (),
        seed: ()
    };

    inline_response_200 response = check azureOpenAI->/deployments/[deploymentId]/chat/completions.post(
        request, api\-version = apiVersion);

    createChatCompletionResponse completion = check response.ensureType();
    test:assertTrue(completion.choices.length() > 0);
    completionUsage? usage = completion.usage;
    test:assertTrue(usage is completionUsage, "Expected usage statistics");
    if usage is completionUsage {
        test:assertEquals(usage.total_tokens, 24);
    }
}

@test:Config {
    groups: ["mock_tests"]
}
isolated function testChatCompletionWithToolCalls() returns error? {
    createChatCompletionRequest request = {
        messages: [{role: "user", "content": "What is the weather in Colombo?"}],
        tools: [
            {
                'type: "function",
                'function: {
                    name: "get_current_weather",
                    description: "Get the current weather for a location",
                    parameters: {}
                }
            }
        ],
        tool_choice: "auto"
    };

    inline_response_200 response = check azureOpenAI->/deployments/[deploymentId]/chat/completions.post(
        request, api\-version = apiVersion);

    createChatCompletionResponse completion = check response.ensureType();
    createChatCompletionResponse_choices choice = completion.choices[0];
    test:assertEquals(choice.finish_reason, "tool_calls");

    chatCompletionMessageToolCall[]? toolCalls = choice.message.tool_calls;
    test:assertTrue(toolCalls is chatCompletionMessageToolCall[], "Expected tool calls in the response");
    if toolCalls is chatCompletionMessageToolCall[] {
        test:assertEquals(toolCalls.length(), 1);
        test:assertEquals(toolCalls[0].'function.name, "get_current_weather");
    }
}

@test:Config {
    groups: ["mock_tests"]
}
isolated function testChatCompletionWithMultipleChoices() returns error? {
    createChatCompletionRequest request = {
        messages: [{role: "user", "content": "Give me three greetings"}],
        n: 3
    };

    inline_response_200 response = check azureOpenAI->/deployments/[deploymentId]/chat/completions.post(
        request, api\-version = apiVersion);

    createChatCompletionResponse completion = check response.ensureType();
    test:assertEquals(completion.choices.length(), 3);
    test:assertEquals(completion.choices[2].index, 2);
}

@test:Config {
    groups: ["mock_tests"]
}
isolated function testChatCompletionWithEmptyMessagesReturnsError() {
    createChatCompletionRequest request = {
        messages: []
    };

    inline_response_200|error response = azureOpenAI->/deployments/[deploymentId]/chat/completions.post(
        request, api\-version = apiVersion);

    test:assertTrue(response is error, "Expected an error for an empty messages array");
    if response is http:ClientRequestError {
        test:assertEquals(response.detail().statusCode, 400);
    }
}
