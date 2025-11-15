Unbreakable Rules:

- Files always have a blank line at the end
- Always write tests that test behavior, not the implementation
- Never mock in tests
- Small, pure, functions whenever possible
- Immutable values whenever possible
- Never take a shortcut
- Ultra think through problems before taking the hacky solution
- Use real schemas/types in tests, never redefine them

## Peer Review for Complex Operations

When faced with a complex operation or if you are struggling to find the optimal solution, you should seek a peer review from Gemini to get a second opinion and alternative ideas.

**When to Seek a Peer Review:**
- The task involves multiple components or requires significant refactoring.
- The problem is ambiguous, and the best path forward is not clear.
- You are stuck or your proposed solution seems overly complicated.
- The user's request is high-stakes and could have significant impact.

**Peer Review Process:**
1.  **Formulate the Problem:** Clearly define the problem, your proposed plan, and any specific areas where you are uncertain.
2.  **Invoke Gemini:** Use the `gemini` command to ask for a peer review. Provide all the relevant context, including code snippets, your plan, and the specific problem you're facing.
    -   **Example Prompt:** `gemini -p "I am working on [task]. My plan is to [your plan]. I'm concerned about [specific concern]. Can you peer review this plan, suggest any alternatives, and highlight potential risks? Here is the relevant code: @<file_path>"`
3.  **Evaluate Suggestions:** Analyze Gemini's feedback and suggestions.
4.  **Make the Final Decision:** As the primary agent, you have the final say. Synthesize Gemini's input with your own analysis to determine the best course of action. You are not required to follow Gemini's suggestions, but you must consider them.
5.  **Implement:** Proceed with the implementation based on your final decision.

______________________________________________________________________

## Specialized Subagents Available

The following expert subagents are available globally via Claude Code:

- **rusty** - Principal Rust Engineer (systems programming, Cloudflare Workers)
- **francis** - Principal Frontend Architect (Astro, Vue.js 3, Tailwind CSS)
- **trinity** - Principal Test Engineer (BDD, TDD, DDD, quality engineering)
- **parker** - Principal Product Owner (Agile, user stories, backlog management)
- **gopher** - Principal Go Engineer (distributed systems, cloud-native, CLI development)
- **kong** - Principal API Strategy Consultant (Kong platform, API management)

Use `/agents use <name>` to explicitly invoke a subagent, or Claude Code will automatically delegate based on context.
