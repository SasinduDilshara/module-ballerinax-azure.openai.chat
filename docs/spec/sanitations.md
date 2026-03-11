_Authors_: @ballerina-platform \
_Created_: 2026/03/11 \
_Updated_: 2026/03/11 \
_Edition_: Swan Lake

# Sanitation for OpenAPI specification

This document records the sanitation done on top of the official OpenAPI specification from Azure AI Foundry Models Service.
The OpenAPI specification is obtained from the [Azure REST API Specs](https://github.com/Azure/azure-rest-api-specs/blob/main/specification/ai/data-plane/OpenAI.v1/azure-v1-v1-generated.yaml).
These changes are done in order to improve the overall usability, and as workarounds for some known language limitations.

1. **Converted nullable type arrays to `nullable: true`**:

   - **Changed Schemas**: Multiple schemas throughout the specification
   - **Original**: `type: ["string", "null"]` (OpenAPI 3.1.x+ style)
   - **Updated**: `type: string` with `nullable: true`
   - **Reason**: Type arrays are not supported in OpenAPI 3.0.0. The `nullable: true` property is the 3.0.0 equivalent for expressing nullable types.

2. **Removed `default: null` properties**:

   - **Changed Schemas**: Multiple schemas including request and response types
   - **Original**: `default: null`
   - **Updated**: Removed the `default` parameter
   - **Reason**: Temporary workaround until the Ballerina OpenAPI tool supports OpenAPI Specification version v3.1.x+.

3. **Converted `const` to `enum`**:

   - **Changed Schemas**: Multiple schemas with constant values
   - **Original**: `const: "value"`
   - **Updated**: `enum: ["value"]`
   - **Reason**: The `const` keyword is not supported in OpenAPI 3.0.0. Using `enum` with a single value achieves the same effect.

4. **Converted `anyOf`/`oneOf` with null types**:

   - **Changed Schemas**: Multiple schemas using `anyOf`/`oneOf` with `{"type": "null"}`
   - **Original**: `anyOf: [{"type": "string"}, {"type": "null"}]`
   - **Updated**: `type: string` with `nullable: true`
   - **Reason**: The `anyOf`/`oneOf` with `{"type": "null"}` pattern for expressing nullable types is not supported in OpenAPI 3.0.0. The `nullable: true` property is used instead.

5. **Removed OpenAPI 3.2.0-specific features**:

   - Removed `pathItems` from components (not supported in 3.0.0)
   - Removed `propertyNames`, `unevaluatedProperties`, and other JSON Schema draft features
   - **Reason**: These keywords are not part of the OpenAPI 3.0.0 specification.

6. **Fixed `exclusiveMinimum`/`exclusiveMaximum` format**:

   - **Original**: Boolean form (OpenAPI 3.1.x+)
   - **Updated**: Numeric form (OpenAPI 3.0.0)
   - **Reason**: OpenAPI 3.0.0 uses numeric values for exclusive boundaries, not boolean flags.

7. **Extracted only Chat Completions endpoint from the full specification**:

   - **Original**: Full Azure AI Foundry Models Service spec with all endpoints (batches, responses, files, etc.)
   - **Updated**: Only the `/chat/completions` path and its related schemas are retained
   - **Reason**: This connector module only covers the Chat Completions API. Including unrelated endpoints would generate unnecessary code.

## OpenAPI cli command

The following command was used to generate the Ballerina client from the OpenAPI specification. The command should be executed from the repository root directory.

```bash
bal openapi -i docs/spec/openapi.yaml --mode client --license docs/license.txt -o ballerina
```

Note: The license year is hardcoded to 2026, change if necessary.
