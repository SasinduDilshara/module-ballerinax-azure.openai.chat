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

// `inline_response_200` is a union of the non-streaming and streaming response
// shapes. These helper records mirror each member so tests can bind the response
// to a concrete, field-addressable type via `ensureType`.
type ChatCompletionResponse record {
    string id;
    OpenAI\.CreateChatCompletionResponseChoices[] choices;
    int created;
    string model;
    string system_fingerprint?;
    "chat.completion" 'object;
    OpenAI\.CompletionUsage usage?;
    inline_response_200_prompt_filter_results[] prompt_filter_results?;
};

type StreamingChatCompletionResponse record {
    string id;
    OpenAI\.CreateChatCompletionStreamResponseChoices[] choices;
    int created;
    string model;
    string system_fingerprint?;
    "chat.completion.chunk" 'object;
    OpenAI\.CompletionUsage usage?;
    OpenAI\.ChatCompletionStreamResponseDelta delta?;
    AzureContentFilterResultForChoice content_filter_results?;
};

// Builds a representative value of every response-side generated type. Azure
// populates these only in specific situations (content filtering, log
// probabilities, audio output, tool/function calls), so constructing them here
// verifies the generated record shapes are usable and keeps them covered.
@test:Config {
    groups: ["mock_tests"]
}
isolated function testResponseModelTypesAreConstructable() {
    // Content filtering result hierarchy.
    AzureContentFilterSeverityResult severity = {filtered: false, severity: "safe"};
    AzureContentFilterDetectionResult detected = {filtered: false, detected: false};
    AzureContentFilterBlocklistResult_details blocklistDetail = {filtered: false, id: "blocklist-1"};
    AzureContentFilterBlocklistResult blocklist = {filtered: false, details: [blocklistDetail]};
    AzureContentFilterCustomTopicResult_details topicDetail = {detected: false, id: "topic-1"};
    AzureContentFilterCustomTopicResult topics = {filtered: false, details: [topicDetail]};
    AzureContentFilterResultForChoice_protected_material_code_citation citationInfo = {URL: "https://lib", license: "MIT"};
    AzureContentFilterResultForChoice_protected_material_code withCitation =
        {filtered: false, detected: false, citation: citationInfo};
    AzureContentFilterCompletionTextSpan span = {completion_start_offset: 0, completion_end_offset: 5};
    AzureContentFilterCompletionTextSpanDetectionResult withSpans =
        {filtered: false, detected: false, details: [span]};
    AzureContentFilterResultForChoice choiceResults = {
        sexual: severity,
        profanity: detected,
        custom_blocklists: blocklist,
        custom_topics: topics,
        protected_material_text: detected,
        protected_material_code: withCitation,
        ungrounded_material: withSpans
    };

    test:assertEquals(severity.severity, "safe");
    test:assertEquals(blocklistDetail.id, "blocklist-1");
    test:assertEquals(topics.details, [topicDetail]);
    test:assertEquals(withCitation.citation?.license, "MIT");
    test:assertEquals(withSpans.details[0].completion_end_offset, 5);
    test:assertTrue(choiceResults.sexual is AzureContentFilterSeverityResult);
    test:assertTrue(choiceResults.ungrounded_material is AzureContentFilterCompletionTextSpanDetectionResult);

    // Prompt filter result hierarchy.
    AzureContentFilterResultForPrompt_content_filter_results promptFilterCategories =
        {sexual: severity, jailbreak: detected, indirect_attack: detected};
    AzureContentFilterResultForPrompt promptResults =
        {prompt_index: 0, content_filter_results: promptFilterCategories};
    inline_response_200_prompt_filter_results promptFilter =
        {prompt_index: 0, content_filter_results: promptResults};
    test:assertEquals(promptFilter.prompt_index, 0);

    // Token log-probability types.
    OpenAI\.ChatCompletionTokenLogprobTopLogprobs topLogprob = {token: "Hi", logprob: -0.2d, bytes: [72, 105]};
    OpenAI\.ChatCompletionTokenLogprob tokenLogprob =
        {token: "Hello", logprob: -0.1d, bytes: [72, 101], top_logprobs: [topLogprob]};
    OpenAI\.CreateChatCompletionResponseChoicesLogprobs logprobs = {content: [tokenLogprob], refusal: ()};
    test:assertEquals(logprobs.content, [tokenLogprob]);

    // Usage breakdown types.
    OpenAI\.CompletionUsagePromptTokensDetails promptDetails = {audio_tokens: 2, cached_tokens: 4};
    OpenAI\.CompletionUsageCompletionTokensDetails completionDetails =
        {accepted_prediction_tokens: 1, audio_tokens: 3, reasoning_tokens: 5, rejected_prediction_tokens: 2};
    OpenAI\.CompletionUsage usage = {
        prompt_tokens: 20,
        completion_tokens: 30,
        total_tokens: 50,
        prompt_tokens_details: promptDetails,
        completion_tokens_details: completionDetails
    };
    test:assertEquals(usage.total_tokens, 50);

    // Response message types.
    OpenAI\.ChatCompletionResponseMessageFunctionCall functionCall = {name: "legacy_fn", arguments: "{}"};
    OpenAI\.ChatCompletionResponseMessageAudio audio =
        {id: "audio_1", expires_at: 1723095000, data: "BASE64", transcript: "spoken"};
    OpenAI\.ChatCompletionMessageToolCall toolCall =
        {id: "call_1", 'type: "function", 'function: {name: "lookup", arguments: "{}"}};
    OpenAI\.ChatCompletionMessageCustomToolCall customToolCall =
        {id: "call_2", 'type: "custom", custom: {name: "run", input: "echo"}};
    OpenAI\.ChatCompletionResponseMessageAnnotations urlAnnotation =
        {'type: "url_citation", url_citation: {end_index: 5, start_index: 0, url: "https://x", title: "Doc"}};
    OpenAI\.ChatCompletionResponseMessage message = {
        role: "assistant",
        refusal: (),
        content: "answer",
        tool_calls: [toolCall, customToolCall],
        annotations: [urlAnnotation],
        function_call: functionCall,
        audio: audio
    };
    OpenAI\.CreateChatCompletionResponseChoices choice =
        {finish_reason: "stop", index: 0, message: message, logprobs: logprobs, content_filter_results: choiceResults};
    test:assertEquals(choice.message.role, "assistant");
    test:assertEquals(choice.message.tool_calls, [toolCall, customToolCall]);

    // Azure user security context (request-side helper type).
    AzureUserSecurityContext securityContext =
        {application_name: "app", end_user_id: "u", end_user_tenant_id: "t", source_ip: "1.2.3.4"};
    test:assertEquals(securityContext.application_name, "app");
}

// Constructs the streaming response types that are not produced through the
// single non-streaming mock path, keeping those generated types compiled and
// verified. Also confirms `inline_response_200` accepts the streaming member.
@test:Config {
    groups: ["mock_tests"]
}
isolated function testStreamingResponseTypes() {
    OpenAI\.ChatCompletionMessageToolCallChunk toolCallChunk =
        {index: 0, id: "call_1", 'type: "function", 'function: {name: "lookup", arguments: "{}"}};
    OpenAI\.ChatCompletionStreamResponseDelta delta = {
        role: "assistant",
        content: "partial",
        refusal: (),
        tool_calls: [toolCallChunk],
        function_call: {name: "lookup", arguments: "{}"}
    };
    OpenAI\.CreateChatCompletionStreamResponseChoices streamChoice =
        {index: 0, finish_reason: (), delta: delta};

    StreamingChatCompletionResponse streamChunk = {
        id: "chatcmpl-stream-1",
        choices: [streamChoice],
        created: 1723091498,
        model: "gpt-4o-mini",
        system_fingerprint: "fp_stream",
        'object: "chat.completion.chunk"
    };
    test:assertEquals(streamChunk.choices[0].delta.role, "assistant");

    // `inline_response_200` is a union that also accepts the streaming shape.
    inline_response_200 streamResponse = streamChunk;
    test:assertTrue(streamResponse is StreamingChatCompletionResponse);
}
