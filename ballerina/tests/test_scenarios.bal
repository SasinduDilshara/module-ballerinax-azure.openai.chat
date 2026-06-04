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

import ballerina/test;

// Sends a request that uses every message role and content-part variant Azure
// supports (developer/system/user/assistant/tool/function messages, text/image/
// audio/refusal content parts) along with the full set of optional request
// fields (tools, functions, response format, data sources, prediction, modality,
// security context, etc.). This validates that the generated request types model
// real-world payloads correctly.
@test:Config {
    groups: ["mock_tests"]
}
isolated function testRequestWithAllMessageAndContentTypes() returns error? {
    chatCompletionRequestMessage[] messages = [
        {role: "developer", "content": "Be concise."},
        {role: "system", "content": [{'type: "text", text: "You are helpful."}]},
        {
            role: "user",
            "content": [
                {'type: "text", text: "Describe this image and audio."},
                {'type: "image_url", image_url: {url: "https://example.com/img.png", detail: "high"}},
                {'type: "input_audio", input_audio: {data: "BASE64AUDIO", format: "wav"}}
            ]
        },
        {
            role: "assistant",
            "content": [{'type: "refusal", refusal: "I cannot do that."}],
            refusal: "I cannot do that.",
            tool_calls: [{id: "call_1", 'type: "function", 'function: {name: "lookup", arguments: "{}"}}],
            function_call: {name: "lookup", arguments: "{}"}
        },
        {role: "tool", "content": "tool output", tool_call_id: "call_1"},
        {role: "function", name: "lookup", "content": "function output"}
    ];

    createChatCompletionRequest request = {
        messages,
        reasoning_effort: "high",
        max_completion_tokens: 1024,
        logprobs: true,
        top_logprobs: 5,
        modalities: ["text", "audio"],
        prediction: {'type: "content", content: "predicted text"},
        audio: {voice: "alloy", format: "mp3"},
        parallel_tool_calls: true,
        response_format: {
            'type: "json_schema",
            json_schema: {name: "result", description: "structured", schema: {}, strict: true}
        },
        seed: 42,
        stream_options: {include_usage: true},
        tools: [{'type: "function", 'function: {name: "lookup", description: "Look things up", parameters: {}, strict: false}}],
        tool_choice: {'type: "function", 'function: {name: "lookup"}},
        function_call: {name: "lookup"},
        functions: [{name: "lookup", description: "deprecated", parameters: {}}],
        data_sources: [{'type: "azure_search"}],
        store: true,
        metadata: {"team": "platform"},
        logit_bias: {"1234": 50},
        user: "end-user-1"
    };

    inline_response_200 response = check azureOpenAI->/deployments/[deploymentId]/chat/completions.post(
        request, api\-version = apiVersion);
    createChatCompletionResponse completion = check response.ensureType();
    test:assertTrue(completion.choices.length() > 0);
}

// Binds a fully populated Azure response so every optional response-side type is
// exercised: prompt/choice content filters, logprobs, tool & function calls,
// audio output, and the Azure data-source citation context.
@test:Config {
    groups: ["mock_tests"]
}
isolated function testRichResponseBinding() returns error? {
    createChatCompletionRequest request = {
        messages: [{role: "user", "content": "Give me everything"}],
        user: "rich-response"
    };

    inline_response_200 response = check azureOpenAI->/deployments/[deploymentId]/chat/completions.post(
        request, api\-version = apiVersion);
    createChatCompletionResponse completion = check response.ensureType();

    promptFilterResults? promptFilters = completion.prompt_filter_results;
    test:assertTrue(promptFilters is promptFilterResults, "Expected prompt filter results");

    createChatCompletionResponse_choices choice = completion.choices[0];
    test:assertEquals(choice.finish_reason, "tool_calls");
    test:assertTrue(choice.content_filter_results is contentFilterChoiceResults, "Expected choice content filters");
    test:assertTrue(choice.logprobs is createChatCompletionResponse_logprobs, "Expected logprobs");

    chatCompletionResponseMessage message = choice.message;
    test:assertTrue(message.tool_calls is chatCompletionMessageToolCall[], "Expected tool calls");
    test:assertTrue(message.function_call is chatCompletionFunctionCall, "Expected function call");
    test:assertTrue(message.audio is chatCompletionResponseMessage_audio, "Expected audio output");

    azureChatExtensionsMessageContext? context = message.context;
    test:assertTrue(context is azureChatExtensionsMessageContext, "Expected data-source context");
    if context is azureChatExtensionsMessageContext {
        test:assertTrue(context.citations is citation[], "Expected citations");
        test:assertTrue(context.all_retrieved_documents is retrievedDocument[], "Expected retrieved documents");
    }

    completionUsage? usage = completion.usage;
    test:assertTrue(usage is completionUsage, "Expected usage");
    if usage is completionUsage {
        test:assertTrue(usage.prompt_tokens_details is completionUsage_prompt_tokens_details);
        test:assertTrue(usage.completion_tokens_details is completionUsage_completion_tokens_details);
        test:assertEquals(usage.total_tokens, 50);
    }
}

// Constructs the remaining generated types that are not produced through the
// single chat-completions response path: the streaming response shape, the
// `text`/`json_object` response formats and the base error record. This keeps
// those generated types compiled and verified.
@test:Config {
    groups: ["mock_tests"]
}
isolated function testStreamingAndAuxiliaryTypes() returns error? {
    createChatCompletionStreamResponse streamChunk = {
        id: "chatcmpl-stream-1",
        choices: [
            {
                index: 0,
                finish_reason: (),
                delta: {
                    role: "assistant",
                    "content": "partial",
                    refusal: (),
                    tool_calls: [
                        {
                            index: 0,
                            id: "call_1",
                            'type: "function",
                            'function: {name: "lookup", arguments: "{}"}
                        }
                    ],
                    function_call: {name: "lookup", arguments: "{}"}
                }
            }
        ],
        created: 1723091498,
        model: "gpt-4o-mini",
        system_fingerprint: "fp_stream",
        'object: "chat.completion.chunk"
    };
    test:assertEquals(streamChunk.choices[0].delta.role, "assistant");

    // `inline_response_200` is a union of the standard and streaming responses.
    inline_response_200 streamResponse = streamChunk;
    test:assertTrue(streamResponse is createChatCompletionStreamResponse);

    ResponseFormatText textFormat = {'type: "text"};
    ResponseFormatJsonObject jsonObjectFormat = {'type: "json_object"};
    test:assertEquals(textFormat.'type, "text");
    test:assertEquals(jsonObjectFormat.'type, "json_object");

    errorBase err = {code: "rate_limit", message: "Too many requests"};
    test:assertEquals(err.code, "rate_limit");
}
