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
import ballerina/log;

listener http:Listener httpListener = new (9090);

// A mock of the Azure OpenAI Chat Completions endpoint. The behaviour is shaped
// by the incoming request so the tests can exercise realistic scenarios
// (plain completions, tool calls, multiple choices, content filtering, etc.).
//
// The body is bound as `map<json>` so the mock accepts any valid request shape
// (every message role and content-part variant) without re-implementing the
// union data binding of `chat_completions_body` on the server side. `api-version`
// is an optional query parameter, matching `CreateChatCompletionQueries`.
http:Service mockService = service object {

    resource function post chat/completions(@http:Payload map<json> payload,
            string? api\-version = ()) returns json|http:BadRequest {

        // `model` is a required, non-empty string for a valid Azure request.
        json modelField = payload["model"];
        string model = modelField is string ? modelField : "";
        if model.trim() == "" {
            return <http:BadRequest>{body: {"error": {"code": "invalid_request", "message": "model is required"}}};
        }

        json messagesField = payload["messages"];
        json[] messages = messagesField is json[] ? messagesField : [];

        // `messages` is required and must contain at least one message.
        if messages.length() == 0 {
            return <http:BadRequest>{body: {"error": {"code": "invalid_request", "message": "messages must contain at least one message"}}};
        }

        // Scenario 1: the caller provided tools -> respond with a tool call.
        if payload["tools"] is json[] {
            return {
                "id": "chatcmpl-tool-0001",
                "choices": [
                    {
                        "finish_reason": "tool_calls",
                        "index": 0,
                        "message": {
                            "role": "assistant",
                            "content": null,
                            "refusal": null,
                            "tool_calls": [
                                {
                                    "id": "call_abc123",
                                    "type": "function",
                                    "function": {
                                        "name": "get_current_weather",
                                        "arguments": "{\"location\":\"Colombo\"}"
                                    }
                                }
                            ]
                        },
                        "logprobs": {"content": null, "refusal": null},
                        "content_filter_results": {
                            "hate": {"filtered": false, "severity": "safe"},
                            "protected_material_text": {"filtered": false, "detected": false}
                        }
                    }
                ],
                "created": 1723091495,
                "model": model,
                "system_fingerprint": "fp_mock_tool",
                "object": "chat.completion",
                "usage": {"completion_tokens": 18, "prompt_tokens": 42, "total_tokens": 60}
            };
        }

        // Scenario 2: the caller asked for multiple choices via `n`.
        json nField = payload["n"];
        int choiceCount = nField is int ? nField : 1;
        if choiceCount > 1 {
            json[] choices = [];
            foreach int i in 0 ..< choiceCount {
                choices.push({
                    "finish_reason": "stop",
                    "index": i,
                    "message": {
                        "role": "assistant",
                        "content": "Mock choice " + i.toString(),
                        "refusal": null
                    },
                    "logprobs": {"content": null, "refusal": null}
                });
            }
            return {
                "id": "chatcmpl-multi-0002",
                "choices": choices,
                "created": 1723091496,
                "model": model,
                "system_fingerprint": "fp_mock_multi",
                "object": "chat.completion",
                "usage": {"completion_tokens": 11 * choiceCount, "prompt_tokens": 13, "total_tokens": 13 + 11 * choiceCount}
            };
        }

        // Scenario 3: a fully populated response exercising the optional
        // response-side sections (audio output, legacy function call, choice and
        // prompt content filters, log probabilities). Triggered by
        // `user == "rich-response"`.
        if payload["user"] == "rich-response" {
            return {
                "id": "chatcmpl-rich-0003",
                "prompt_filter_results": [
                    {
                        "prompt_index": 0,
                        "content_filter_results": {
                            "prompt_index": 0,
                            "content_filter_results": {
                                "sexual": {"filtered": false, "severity": "safe"},
                                "jailbreak": {"filtered": false, "detected": false},
                                "indirect_attack": {"filtered": false, "detected": false}
                            }
                        }
                    }
                ],
                "choices": [
                    {
                        "finish_reason": "tool_calls",
                        "index": 0,
                        "message": {
                            "role": "assistant",
                            "content": "Here is the answer.",
                            "refusal": null,
                            "tool_calls": [
                                {
                                    "id": "call_xyz",
                                    "type": "function",
                                    "function": {"name": "lookup", "arguments": "{\"q\":\"x\"}"}
                                }
                            ],
                            "function_call": {"name": "legacy_fn", "arguments": "{}"},
                            "audio": {
                                "id": "audio_1",
                                "expires_at": 1723095000,
                                "data": "BASE64",
                                "transcript": "spoken answer"
                            }
                        },
                        "content_filter_results": {
                            "sexual": {"filtered": false, "severity": "safe"},
                            "protected_material_text": {"filtered": false, "detected": false},
                            "protected_material_code": {
                                "filtered": false,
                                "detected": false,
                                "citation": {"URL": "https://lib", "license": "MIT"}
                            },
                            "ungrounded_material": {
                                "filtered": false,
                                "detected": false,
                                "details": [{"completion_start_offset": 0, "completion_end_offset": 5}]
                            }
                        },
                        "logprobs": {
                            "content": [
                                {
                                    "token": "Hello",
                                    "logprob": -0.1,
                                    "bytes": [72, 101],
                                    "top_logprobs": [{"token": "Hi", "logprob": -0.2, "bytes": [72, 105]}]
                                }
                            ],
                            "refusal": null
                        }
                    }
                ],
                "created": 1723091497,
                "model": model,
                "system_fingerprint": "fp_rich",
                "object": "chat.completion",
                "usage": {
                    "prompt_tokens": 20,
                    "completion_tokens": 30,
                    "total_tokens": 50,
                    "prompt_tokens_details": {"audio_tokens": 2, "cached_tokens": 4},
                    "completion_tokens_details": {"accepted_prediction_tokens": 1, "audio_tokens": 3, "reasoning_tokens": 5, "rejected_prediction_tokens": 2}
                }
            };
        }

        // Scenario 4 (default): a single assistant completion with content
        // filtering results and prompt filter results, mirroring a typical
        // Azure response.
        return {
            "id": "chatcmpl-00000",
            "prompt_filter_results": [
                {
                    "prompt_index": 0,
                    "content_filter_results": {
                        "prompt_index": 0,
                        "content_filter_results": {
                            "hate": {"filtered": false, "severity": "safe"},
                            "self_harm": {"filtered": false, "severity": "safe"},
                            "sexual": {"filtered": false, "severity": "safe"},
                            "violence": {"filtered": false, "severity": "safe"},
                            "jailbreak": {"filtered": false, "detected": false},
                            "indirect_attack": {"filtered": false, "detected": false}
                        }
                    }
                }
            ],
            "choices": [
                {
                    "finish_reason": "stop",
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "content": "Test message received! How can I assist you today?",
                        "refusal": null
                    },
                    "content_filter_results": {
                        "hate": {"filtered": false, "severity": "safe"},
                        "self_harm": {"filtered": false, "severity": "safe"},
                        "sexual": {"filtered": false, "severity": "safe"},
                        "violence": {"filtered": false, "severity": "safe"}
                    },
                    "logprobs": {"content": null, "refusal": null}
                }
            ],
            "created": 1723091495,
            "model": model,
            "system_fingerprint": "fp_48196bc67a",
            "object": "chat.completion",
            "usage": {"completion_tokens": 11, "prompt_tokens": 13, "total_tokens": 24}
        };
    }
};

function init() returns error? {
    if isLiveServer {
        log:printInfo("Skipping mock server initialization as the tests are running against a live server");
        return;
    }

    log:printInfo("Initiating mock server...");
    check httpListener.attach(mockService, "/");
    check httpListener.'start();
}
