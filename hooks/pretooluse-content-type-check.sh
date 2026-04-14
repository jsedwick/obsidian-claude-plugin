#!/bin/bash

# PreToolUse hook that reminds Claude about the content type decision tree
# before creating topics or decisions

cat <<'EOF'
⚠️ CONTENT TYPE VALIDATION - Decision Tree Reminder

Before creating this topic/decision, verify it matches the decision tree:

📋 DECISION TREE:

Is this about a conversation you just had?
├─ YES → Use SESSION notes (don't create topic/decision)
└─ NO  → Continue...

Is this a strategic choice between alternatives?
├─ YES → Create DECISION (only if alternatives were really considered)
└─ NO  → Continue...

Is this persistent technical knowledge (how-to, implementation, troubleshooting)?
├─ YES → Create TOPIC
└─ NO  → Reconsider - might belong in session notes

❌ DON'T create topics for:
- Investigation details (belongs in session)
- One-time bug fixes (belongs in session)
- Conversation-specific context
- Transient debugging information

✅ DO create topics for:
- Reusable how-to guides
- Implementation details others can reference
- Troubleshooting procedures
- Architecture explanations

❌ DON'T create decisions for:
- Bug fixes or implementation details
- How-to guides or configuration steps
- Any choice where alternatives weren't considered

✅ DO create decisions for:
- Strategic architectural choices between alternatives
- Technology selection decisions (framework A vs B)
- Major design decisions with tradeoffs documented

If you're unsure, the content likely belongs in session notes.
EOF

exit 0  # Inject as context, don't block
