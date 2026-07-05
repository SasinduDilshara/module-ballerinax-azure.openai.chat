_Authors_: @ballerina-platform \
_Created_: 2026/03/11 \
_Updated_: 2026/03/11 \
_Edition_: Swan Lake

# Sanitation for OpenAPI specification

This document records the sanitation done on top of the official OpenAPI specification from Azure AI Foundry Models Service.

The OpenAPI specification is obtained from the [Azure REST API Specs](https://github.com/Azure/azure-rest-api-specs/blob/main/specification/ai/data-plane/OpenAI.v1/azure-v1-v1-generated.yaml).
These changes are done in order to improve the overall usability, and as workarounds for some known language limitations.

1. **Extracted only Chat Completions endpoint from the full specification**:

   - **Original**: Full Azure AI Foundry Models Service spec with all endpoints (batches, responses, files, etc.)
   - **Updated**: Only the `/chat/completions` path and its related schemas are retained
   - **Reason**: This connector module only covers the Chat Completions API. Including unrelated endpoints would generate unnecessary code.

2. **Converted nullable type arrays to `nullable: true`**:

   - **Changed Schemas**: Multiple schemas throughout the specification
   - **Original**: `type: ["string", "null"]` (OpenAPI 3.1.x+ style)
   - **Updated**: `type: string` with `nullable: true`
   - **Reason**: Type arrays are not supported in OpenAPI 3.0.0. The `nullable: true` property is the 3.0.0 equivalent for expressing nullable types.

3. **Removed `default: null` properties**:

   - **Changed Schemas**: Multiple schemas including request and response types
   - **Original**: `default: null`
   - **Updated**: Removed the `default` parameter
   - **Reason**: Temporary workaround until the Ballerina OpenAPI tool supports OpenAPI Specification version v3.1.x+.

4. **Converted `const` to `enum`**:

   - **Changed Schemas**: Multiple schemas with constant values
   - **Original**: `const: "value"`
   - **Updated**: `enum: ["value"]`
   - **Reason**: The `const` keyword is not supported in OpenAPI 3.0.0. Using `enum` with a single value achieves the same effect.

5. **Converted `anyOf`/`oneOf` with null types**:

   - **Changed Schemas**: Multiple schemas using `anyOf`/`oneOf` with `{"type": "null"}`
   - **Original**: `anyOf: [{"type": "string"}, {"type": "null"}]`
   - **Updated**: `type: string` with `nullable: true`
   - **Reason**: The `anyOf`/`oneOf` with `{"type": "null"}` pattern for expressing nullable types is not supported in OpenAPI 3.0.0. The `nullable: true` property is used instead.

6. **Removed OpenAPI 3.2.0-specific features**:

   - Removed `pathItems` from components (not supported in 3.0.0)
   - Removed `propertyNames`, `unevaluatedProperties`, and other JSON Schema draft features
   - **Reason**: These keywords are not part of the OpenAPI 3.0.0 specification.

7. **Fixed `exclusiveMinimum`/`exclusiveMaximum` format**:

   - **Original**: Boolean form (OpenAPI 3.1.x+)
   - **Updated**: Numeric form (OpenAPI 3.0.0)
   - **Reason**: OpenAPI 3.0.0 uses numeric values for exclusive boundaries, not boolean flags.

8. **Renamed schemas to Ballerina-friendly type names**:

   - **Changed Schemas**: Only the schemas whose generated Ballerina type name was not a valid UpperCamelCase identifier (anonymous inline records the tool already emitted without a name were left unchanged).
   - **Original**:
      - Schema keys carrying the `OpenAI.` namespace prefix (e.g. `OpenAI.ChatCompletionTool`), which the tool emitted as escaped-dot type names (`OpenAI\.ChatCompletionTool`).
      - Inline request/response body and nested object schemas the tool named with underscores or a lowercase start (e.g. `chat_completions_body`, `inline_response_200`, `AzureContentFilterResultForChoice_protected_material_code`).
   - **Updated**:
      - Dropped the dot from namespaced keys, keeping the prefix (`OpenAI.ChatCompletionTool` → `OpenAIChatCompletionTool`).
      - Extracted the named inline schemas into components with UpperCamelCase names (`chat_completions_body` → `ChatCompletionsBody`, `inline_response_200` → `InlineResponse200`, `AzureContentFilterResultForChoice_protected_material_code` → `AzureContentFilterResultForChoiceProtectedMaterialCode`) and updated every `$ref`. Structurally identical `error` objects continue to share a single `AzureContentFilterResultForChoiceError` type.
   - **Reason**: Ballerina type names must be valid UpperCamelCase identifiers. Dots, underscores, and lowercase starts force backslash-escaped or non-idiomatic type names, which hurts the connector's usability.

9. **Made the nullable `logprobs` `$ref` property actually nullable via `allOf`**:

   - **Changed Schemas**: `OpenAICreateChatCompletionResponseChoices` — the `logprobs` property.
   - **Original**: A `$ref` with a sibling `nullable: true`:

     ```yaml
     logprobs:
       $ref: '#/components/schemas/OpenAICreateChatCompletionResponseChoicesLogprobs'
       nullable: true
     ```

   - **Updated**: Moved the `$ref` under an `allOf` so the sibling `nullable: true` is honored:

     ```yaml
     logprobs:
       allOf:
       - $ref: '#/components/schemas/OpenAICreateChatCompletionResponseChoicesLogprobs'
       nullable: true
     ```

   - **Reason**: In OpenAPI 3.0.0 a `$ref` overrides any sibling keywords, so the sibling `nullable: true` was ignored and the required `logprobs` field was generated as non-nullable (`OpenAICreateChatCompletionResponseChoicesLogprobs`). Azure returns `"logprobs": null` in every choice when log probabilities are not requested, so this required field must be nullable. Wrapping the `$ref` in `allOf` lets `nullable: true` apply, generating `OpenAICreateChatCompletionResponseChoicesLogprobs?`.

## OpenAPI cli command

The following command was used to generate the Ballerina client from the OpenAPI specification. The command should be executed from the repository root directory.

```bash
bal openapi -i docs/spec/openapi.yaml --mode client --license docs/license.txt -o ballerina
```
