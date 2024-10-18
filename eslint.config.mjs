import js from "@eslint/js";
import eslintPluginYml from "eslint-plugin-yml";

export default [
  js.configs.recommended,
  ...eslintPluginYml.configs["flat/standard"],
  {
    rules: {
      "yml/block-mapping-colon-indicator-newline": ["error", "never"],
      "yml/block-mapping-question-indicator-newline": ["error", "never"],
      "yml/block-mapping": ["error", "always"],
      "yml/block-sequence-hyphen-indicator-newline": ["error", "never"],
      "yml/block-sequence": [
        "error",
        {
          singleline: "always",
          multiline: "always",
        },
      ],
      "yml/file-extension": ["warn", { extension: "yml", caseSensitive: true }],
      "yml/indent": [
        "error",
        2,
        {
          indentBlockSequences: true,
          indicatorValueIndent: 2,
        },
      ],
      "yml/key-name-casing": [
        "error",
        {
          camelCase: true,
          PascalCase: false,
          SCREAMING_SNAKE_CASE: true,
          "kebab-case": true,
          snake_case: true,
          ignores: [],
        },
      ],
      "yml/no-empty-document": ["error"],
      "yml/no-empty-key": ["error"],
      "yml/no-empty-mapping-value": ["error"],
      "yml/no-empty-sequence-entry": ["error"],
      "yml/no-tab-indent": ["error"],
      "yml/no-trailing-zeros": ["error"],
      "yml/plain-scalar": ["error", "always"],
      "yml/quotes": [
        "error",
        {
          prefer: "double",
          avoidEscape: true,
        },
      ],
      "yml/require-string-key": ["error"],
      // TODO: set rules for github actions, docker compose, etc
      // "yml/sort-keys": ["error", {}],
      // "yml/sort-sequence-values": ["error", {}],
      "yml/vue-custom-block/no-parsing-error": ["error"],
      "yml/flow-mapping-curly-newline": ["error", "never"],
      "yml/flow-mapping-curly-spacing": ["error", "always"],
      "yml/flow-sequence-bracket-newline": ["error", "consistent"],
      "yml/flow-sequence-bracket-spacing": ["error", "always"],
      "yml/key-spacing": [
        "error",
        {
          beforeColon: false,
          afterColon: true,
          mode: "strict",
        },
      ],
      "yml/no-irregular-whitespace": ["error"],
      "yml/no-multiple-empty-lines": ["error", { max: 1 }],
      "yml/spaced-comment": [
        "error",
        "always",
        {
          exceptions: [],
          markers: [],
        },
      ],
    },
  },
  {
    ignores: ["pnpm-lock.yaml"],
  },
];
