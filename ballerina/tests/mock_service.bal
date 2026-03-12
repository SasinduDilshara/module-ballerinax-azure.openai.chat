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

http:Service mockService = service object {

    resource function post chat/completions(@http:Payload json payload) returns json|http:BadRequest {
        json|error messages = payload.messages;
        json|error model = payload.model;
        if messages is error || model is error {
            return http:BAD_REQUEST;
        }

        json|error tools = payload.tools;
        if tools is json[] && tools.length() > 0 {
            return {
                "id": "chatcmpl-mock001",
                "object": "chat.completion",
                "created": 1723091495,
                "model": model,
                "choices": [
                    {
                        "index": 0,
                        "message": {
                            "role": "assistant",
                            "content": null,
                            "refusal": null,
                            "tool_calls": [
                                {
                                    "id": "call_mock001",
                                    "type": "function",
                                    "function": {
                                        "name": "get_weather",
                                        "arguments": "{\"location\":\"Seattle\"}"
                                    }
                                }
                            ]
                        },
                        "logprobs": {
                            "content": null,
                            "refusal": null
                        },
                        "finish_reason": "tool_calls"
                    }
                ],
                "usage": {
                    "prompt_tokens": 50,
                    "completion_tokens": 20,
                    "total_tokens": 70
                },
                "prompt_filter_results": [
                    {
                        "prompt_index": 0,
                        "content_filter_results": {
                            "sexual": {"filtered": false, "severity": "safe"},
                            "hate": {"filtered": false, "severity": "safe"},
                            "violence": {"filtered": false, "severity": "safe"},
                            "self_harm": {"filtered": false, "severity": "safe"}
                        }
                    }
                ]
            };
        }

        return {
            "id": "chatcmpl-mock001",
            "object": "chat.completion",
            "created": 1723091495,
            "model": model,
            "choices": [
                {
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "content": "Ballerina is an open-source programming language designed for cloud-native development.",
                        "refusal": null
                    },
                    "logprobs": {
                        "content": null,
                        "refusal": null
                    },
                    "finish_reason": "stop"
                }
            ],
            "usage": {
                "prompt_tokens": 10,
                "completion_tokens": 15,
                "total_tokens": 25
            },
            "prompt_filter_results": [
                {
                    "prompt_index": 0,
                    "content_filter_results": {
                        "sexual": {"filtered": false, "severity": "safe"},
                        "hate": {"filtered": false, "severity": "safe"},
                        "violence": {"filtered": false, "severity": "safe"},
                        "self_harm": {"filtered": false, "severity": "safe"}
                    }
                }
            ]
        };
    }

};

function init() returns error? {
    if isLiveServer {
        log:printInfo("Skipping mock server initialization as tests are running on live server");
        return;
    }
    log:printInfo("Initiating mock server...");
    check httpListener.attach(mockService, "/");
    check httpListener.'start();
}
