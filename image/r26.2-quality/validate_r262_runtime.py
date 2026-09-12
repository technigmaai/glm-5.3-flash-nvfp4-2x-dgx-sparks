from vllm.entrypoints.chat_utils import _postprocess_messages
from vllm.parser.engine.parser_engine import ParserEngine


def assistant_tool_call(arguments, name="write"):
    return [
        {
            "role": "assistant",
            "content": "",
            "tool_calls": [
                {
                    "id": "call_0",
                    "type": "function",
                    "function": {"name": name, "arguments": arguments},
                }
            ],
        }
    ]


cases = [
    ({"a": 1}, {"a": 1}),
    ('{"a": 1}', {"a": 1}),
    ('{"cmd": "unterminated', {}),
    ("[]", {}),
    ("42", {}),
    ("true", {}),
    ('"hello"', {}),
    ("null", {}),
    (None, {}),
    ("", {}),
]

for supplied, expected in cases:
    messages = assistant_tool_call(supplied)
    if supplied is None:
        del messages[0]["tool_calls"][0]["function"]["arguments"]
    _postprocess_messages(messages)
    actual = messages[0]["tool_calls"][0]["function"]["arguments"]
    assert actual == expected, (supplied, actual, expected)

assert hasattr(ParserEngine, "_json_prefix_terminator")
assert ParserEngine._json_prefix_terminator('{"a": "x') == '"}'
assert ParserEngine._json_prefix_terminator('{"count": ') == "null}"

print("runtime_validation=passed cases=12")
