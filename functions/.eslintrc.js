module.exports = {
    env: {
        es6: true,
        node: true,
    },
    parserOptions: {
        ecmaVersion: "latest",
    },
    extends: [
        "eslint:recommended"
        // Removed "google"
    ],
    rules: {
        // Disable annoying Google-specific restrictions
        "no-restricted-globals": "off",
        "prefer-arrow-callback": "off",
        "quotes": "off",
        "require-jsdoc": "off",
        "max-len": "off",
        "indent": "off",
        "object-curly-spacing": "off",
        "comma-dangle": "off"
    },
    overrides: [
        {
            files: ["**/*.spec.*"],
            env: {
                mocha: true,
            },
            rules: {},
        },
    ],
    globals: {},
};
