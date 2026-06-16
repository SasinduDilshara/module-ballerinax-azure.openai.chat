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

// Builds a representative value of every response-side / data-source generated
// type. Azure populates these only in specific situations (content filtering,
// log probabilities, audio output, retrieval augmentation), so constructing them
// here verifies the generated record shapes are usable and keeps them covered.
@test:Config {
    groups: ["mock_tests"]
}
isolated function testResponseModelTypesAreConstructable() {
    // Content filtering result hierarchy.
    contentFilterResultBase base = {filtered: false};
    contentFilterSeverityResult severity = {filtered: false, severity: "safe"};
    contentFilterDetectedResult detected = {filtered: false, detected: false};
    contentFilterIdResult idResult = {filtered: false, id: "blocklist-1"};
    contentFilterDetailedResults detailed = {filtered: false, details: [idResult]};
    contentFilterDetectedWithCitationResult_citation citationInfo = {URL: "https://lib", license: "MIT"};
    contentFilterDetectedWithCitationResult withCitation = {filtered: false, detected: false, citation: citationInfo};
    contentFilterCompletionTextSpan span = {completion_start_offset: 0, completion_end_offset: 5};
    contentFilterDetectedWithCompletionTextSpansResult withSpans =
        {filtered: false, detected: false, details: [span]};
    contentFilterResultsBase resultsBase = {sexual: severity, profanity: detected, custom_blocklists: detailed};
    contentFilterPromptResults promptResults = {jailbreak: detected, indirect_attack: detected};
    contentFilterChoiceResults choiceResults = {
        protected_material_text: detected,
        protected_material_code: withCitation,
        ungrounded_material: withSpans
    };

    test:assertFalse(base.filtered);
    test:assertEquals(severity.severity, "safe");
    test:assertEquals(idResult.id, "blocklist-1");
    test:assertEquals(detailed.details.length(), 1);
    test:assertEquals(withCitation.citation?.license, "MIT");
    test:assertEquals(withSpans.details[0].completion_end_offset, 5);
    test:assertTrue(resultsBase.sexual is contentFilterSeverityResult);
    test:assertTrue(promptResults.jailbreak is contentFilterDetectedResult);
    test:assertTrue(choiceResults.ungrounded_material is contentFilterDetectedWithCompletionTextSpansResult);

    // Prompt filter wrapper.
    promptFilterResult promptFilter = {prompt_index: 0, content_filter_results: promptResults};
    test:assertEquals(promptFilter.prompt_index, 0);

    // Token log-probability types.
    chatCompletionTokenLogprob_top_logprobs topLogprob = {token: "Hi", logprob: -0.2d, bytes: [72, 105]};
    chatCompletionTokenLogprob tokenLogprob =
        {token: "Hello", logprob: -0.1d, bytes: [72, 101], top_logprobs: [topLogprob]};
    createChatCompletionResponse_logprobs logprobs = {content: [tokenLogprob], refusal: ()};
    test:assertEquals(logprobs.content, [tokenLogprob]);

    // Usage breakdown types.
    completionUsage_prompt_tokens_details promptDetails = {audio_tokens: 2, cached_tokens: 4};
    completionUsage_completion_tokens_details completionDetails =
        {accepted_prediction_tokens: 1, audio_tokens: 3, reasoning_tokens: 5, rejected_prediction_tokens: 2};
    completionUsage usage = {
        prompt_tokens: 20,
        completion_tokens: 30,
        total_tokens: 50,
        prompt_tokens_details: promptDetails,
        completion_tokens_details: completionDetails
    };
    test:assertEquals(usage.total_tokens, 50);

    // Response message types.
    chatCompletionFunctionCall functionCall = {name: "legacy_fn", arguments: "{}"};
    chatCompletionResponseMessage_audio audio =
        {id: "audio_1", expires_at: 1723095000, data: "BASE64", transcript: "spoken"};
    chatCompletionResponseMessage message = {
        role: "assistant",
        refusal: (),
        content: "answer",
        function_call: functionCall,
        audio: audio
    };
    createChatCompletionResponse_choices choice = {finish_reason: "stop", index: 0, message: message, logprobs: logprobs};
    test:assertEquals(choice.message.role, "assistant");

    // Azure data-source citation context.
    citation cite = {content: "doc", title: "Doc", url: "https://x", filepath: "/d", chunk_id: "c1", rerank_score: 0.91d};
    retrievedDocument doc = {
        content: "retrieved",
        search_queries: ["weather colombo"],
        data_source_index: 0,
        original_search_score: 0.8d,
        filter_reason: "score"
    };
    azureChatExtensionsMessageContext context =
        {intent: "weather", citations: [cite], all_retrieved_documents: [doc]};
    test:assertEquals(context.citations, [cite]);
    test:assertEquals(doc.filter_reason, "score");

    // Request-common base and its overridable members, plus content-part aliases.
    chatCompletionsRequestCommon common = {temperature: 0.5d, max_tokens: 100, logit_bias: {}};
    chatCompletionRequestDeveloperMessageContentPart developerPart = {'type: "text", text: "dev"};
    chatCompletionRequestToolMessageContentPart toolPart = {'type: "text", text: "tool"};
    userSecurityContext securityContext =
        {application_name: "app", end_user_id: "u", end_user_tenant_id: "t", source_ip: "1.2.3.4"};
    test:assertEquals(common.max_tokens, 100);
    test:assertEquals(developerPart.text, "dev");
    test:assertEquals(toolPart.text, "tool");
    test:assertEquals(securityContext.application_name, "app");
}
