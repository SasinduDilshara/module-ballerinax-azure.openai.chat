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

import ballerina/os;
import ballerina/test;

configurable boolean isLiveServer = os:getEnv("IS_LIVE_SERVER") == "true";
configurable string token = isLiveServer ? os:getEnv("AZURE_OPENAI_TOKEN") : "test";
configurable string serviceUrl = isLiveServer ? os:getEnv("AZURE_OPENAI_SERVICE_URL") : "http://localhost:9090";
final string mockServiceUrl = "http://localhost:9090";
final Client azureOpenAIChat = check initClient();

function initClient() returns Client|error {
    if isLiveServer {
        return new ({auth: {token}}, serviceUrl);
    }
    return new ({auth: {token}}, mockServiceUrl);
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testChatCompletion() returns error? {
    chat_completions_body request = {
        model: "gpt-4o-mini",
        messages: [
            {role: "user", "content": "What is Ballerina?"}
        ]
    };
    inline_response_200 response = check azureOpenAIChat->/chat/completions.post(request);
    record {string id; OpenAI\.CreateChatCompletionResponseChoices[] choices; int created; string model; string system_fingerprint?; "chat.completion" 'object; OpenAI\.CompletionUsage usage?; inline_response_200_prompt_filter_results[] prompt_filter_results?;} chatResponse = check response.ensureType();
    test:assertTrue(chatResponse.choices.length() > 0, msg = "Expected at least one choice");
    test:assertEquals(chatResponse.choices[0].finish_reason, "stop", msg = "Expected finish reason to be 'stop'");
    test:assertTrue(chatResponse.choices[0].message.content is string, msg = "Expected message content to be a string");
}

@test:Config {
    groups: ["live_tests", "mock_tests"]
}
isolated function testChatCompletionWithToolCall() returns error? {
    chat_completions_body request = {
        model: "gpt-4o-mini",
        messages: [
            {role: "user", "content": "What is the weather in Seattle?"}
        ],
        tools: [
            <OpenAI\.ChatCompletionTool>{
                'type: "function",
                'function: {
                    name: "get_weather",
                    description: "Get the current weather for a location",
                    parameters: {
                        "type": "object",
                        "properties": {
                            "location": {
                                "type": "string",
                                "description": "The city name"
                            }
                        },
                        "required": ["location"]
                    }
                }
            }
        ]
    };
    inline_response_200 response = check azureOpenAIChat->/chat/completions.post(request);
    record {string id; OpenAI\.CreateChatCompletionResponseChoices[] choices; int created; string model; string system_fingerprint?; "chat.completion" 'object; OpenAI\.CompletionUsage usage?; inline_response_200_prompt_filter_results[] prompt_filter_results?;} chatResponse = check response.ensureType();
    test:assertTrue(chatResponse.choices.length() > 0, msg = "Expected at least one choice");
    test:assertEquals(chatResponse.choices[0].finish_reason, "tool_calls", msg = "Expected finish reason to be 'tool_calls'");
}
