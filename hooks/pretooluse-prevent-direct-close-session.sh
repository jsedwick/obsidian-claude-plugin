#!/bin/bash

# PreToolUse hook to prevent AI from directly calling close_session
# The close_session tool should ONLY be invoked via the /close slash command

# Read the tool call parameters from stdin
TOOL_PARAMS=$(cat)

# Allow Phase 2 finalization calls (these are made by the AI after Phase 1 completes)
if echo "$TOOL_PARAMS" | grep -q '"finalize":\s*true'; then
  exit 0
fi

# Check if _invoked_by_slash_command is set to true (Phase 1)
if echo "$TOOL_PARAMS" | grep -q '"_invoked_by_slash_command":\s*true'; then
  # This is being called from the /close slash command - allow it
  exit 0
fi

# Block the call and provide helpful message
cat <<'EOF'
🛑 BLOCKED: close_session can only be called via /close command

The close_session tool must ONLY be invoked by the user through the /close slash command.

📌 CORRECT WORKFLOW:
1. User types: /close
2. You provide a summary of the session
3. You call close_session with _invoked_by_slash_command: true

❌ INCORRECT:
- AI calling close_session directly
- AI calling /close command on behalf of user

💡 What to do instead:
If you think the session should be closed, remind the user they can use the /close command when they're ready.
EOF

exit 1  # Block the tool call
