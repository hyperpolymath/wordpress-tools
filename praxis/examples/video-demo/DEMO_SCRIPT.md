# WP Praxis Video Demonstration Script

## Overview
**Duration**: 10 minutes
**Target Audience**: Developers, DevOps Engineers, WordPress Professionals
**Goal**: Demonstrate WP Praxis capabilities from setup to execution

## Setup Before Recording

### Prerequisites Checklist
- [ ] Docker and Docker Compose installed
- [ ] Full-stack demo environment ready
- [ ] Sample workflows loaded
- [ ] Dashboard accessible at localhost:3000
- [ ] WordPress accessible at localhost:8000
- [ ] Clear browser cache and terminal history

### Window Layout
- **Left**: Terminal (for command execution)
- **Right Top**: Dashboard (http://localhost:3000)
- **Right Bottom**: WordPress Admin (http://localhost:8000/wp-admin)

---

## Script

### INTRO (30 seconds)

**[VISUAL: WP Praxis logo/title card]**

**NARRATION:**
"Welcome to WP Praxis - a modular symbolic system that transforms WordPress development through declarative workflows and distributed execution. In the next 10 minutes, I'll show you how WP Praxis enables you to manage WordPress at scale using symbolic reasoning and introspectable design patterns."

**[VISUAL: Fade to architecture diagram]**

---

### PART 1: Architecture Overview (2 minutes)

**[VISUAL: Show architecture diagram from Docs/UML/component-diagram.md]**

**NARRATION:**
"WP Praxis is deliberately polyglot, with each language serving a specific purpose:"

**[VISUAL: Highlight each component as mentioned]**

- "Rust provides high-performance symbolic logic injection"
- "PowerShell handles core symbolic operations"
- "Elixir manages orchestration and state"
- "PHP integrates directly with WordPress"
- "TypeScript powers the dashboard and distributed swarm"

**[VISUAL: Show data flow diagram]**

**NARRATION:**
"Workflows are defined declaratively in YAML or TOML, parsed and validated, then dispatched to the appropriate execution layer. Every operation is traced and can be rolled back."

---

### PART 2: Setup & First Workflow (3 minutes)

**[VISUAL: Terminal - show project directory]**

**COMMAND:**
```bash
cd wp-praxis/examples/demos/full-stack-demo
ls -la
```

**NARRATION:**
"Let's start by launching a complete WP Praxis environment using Docker Compose. This includes WordPress, PostgreSQL for state management, the swarm dispatcher, and multiple workers."

**[VISUAL: Show docker-compose.yml briefly]**

**COMMAND:**
```bash
docker-compose up -d
```

**[VISUAL: Show containers starting]**

**NARRATION:**
"In just a few seconds, we have a complete environment running. Let's check the status."

**COMMAND:**
```bash
docker-compose ps
```

**[VISUAL: Show all containers running]**

**NARRATION:**
"Perfect. All services are up. Now let's open the dashboard."

**[VISUAL: Switch to browser, show Dashboard at localhost:3000]**

**NARRATION:**
"The dashboard provides real-time monitoring of workflows, baselines, and audit reports. But let's start simple - with a basic workflow."

**[VISUAL: Terminal - navigate to workflows]**

**COMMAND:**
```bash
cd ../../workflows
cat simple-option-update.yaml
```

**[VISUAL: Highlight key parts of the workflow]**

**NARRATION:**
"This workflow updates WordPress options with automatic baseline creation and rollback capability. Notice the symbols section - each symbol is a discrete operation that can be dispatched to different execution layers."

**[VISUAL: Scroll to show symbols]**

**NARRATION:**
"We create a baseline before changes, update three options using the Rust injector for performance, verify changes using PHP, then create a post-change baseline and generate a visual diff report."

---

### PART 3: Execute Workflow (2 minutes)

**[VISUAL: Terminal]**

**NARRATION:**
"Let's execute this workflow."

**COMMAND:**
```bash
docker exec wp-praxis-dispatcher \
  pwsh /app/SymbolicEngine/core/symbolic.ps1 \
  -WorkflowPath /wp-praxis/examples/workflows/simple-option-update.yaml \
  -Verbose
```

**[VISUAL: Show execution progress in terminal]**

**NARRATION:**
"Watch as each symbol executes in sequence. The baseline is created, options are updated via the Rust injector, changes are verified, and a post-change baseline is created."

**[VISUAL: Switch to Dashboard - show real-time execution]**

**NARRATION:**
"The dashboard shows real-time progress. Here we can see which symbols have completed, their execution times, and any outputs."

**[VISUAL: Workflow completes]**

**NARRATION:**
"Completed in under a second. Now let's see the results."

**[VISUAL: Dashboard - click on completed workflow]**

---

### PART 4: View Results & Baseline Comparison (2 minutes)

**[VISUAL: Dashboard - workflow details page]**

**NARRATION:**
"Here's the complete execution history. We can see each symbol, its status, execution time, and outputs."

**[VISUAL: Click on "View Diff Report"]**

**[VISUAL: Show visual diff report]**

**NARRATION:**
"The visual diff report shows exactly what changed - three options were modified. We can see the before and after values, making it easy to audit changes."

**[VISUAL: Show charts]**

**NARRATION:**
"Charts provide quick insights into the types of changes and their distribution."

**[VISUAL: Switch to WordPress admin]**

**NARRATION:**
"Let's verify in WordPress. The blog name has been updated to 'My Awesome WordPress Site', and the posts per page setting is now 15."

**[VISUAL: Show Settings > General and Settings > Reading]**

**NARRATION:**
"Perfect. And if we needed to rollback, we could restore from the baseline with a single command."

---

### PART 5: Distributed Execution (2 minutes)

**[VISUAL: Terminal]**

**NARRATION:**
"Now let's see WP Praxis's distributed execution capabilities. We'll scale our workers and run a parallel workflow."

**COMMAND:**
```bash
docker-compose up -d --scale worker=4
```

**[VISUAL: Show 4 workers starting]**

**NARRATION:**
"We now have 4 workers ready to execute tasks in parallel."

**COMMAND:**
```bash
docker exec wp-praxis-dispatcher \
  curl http://localhost:8080/api/workers
```

**[VISUAL: Show JSON with 4 workers]**

**NARRATION:**
"The swarm dispatcher sees all 4 workers. Now let's execute a distributed workflow that creates 300 posts across the workers."

**COMMAND:**
```bash
docker exec wp-praxis-dispatcher \
  pwsh /app/SymbolicEngine/core/symbolic.ps1 \
  -WorkflowPath /wp-praxis/examples/workflows/swarm-distributed.yaml \
  -SwarmDispatcher "http://localhost:8080"
```

**[VISUAL: Dashboard - show parallel execution]**

**NARRATION:**
"Watch as tasks are distributed across workers. Multiple symbols execute simultaneously, with the dispatcher intelligently load-balancing based on worker capacity."

**[VISUAL: Show execution completing]**

**NARRATION:**
"300 posts created in just over 2 seconds - a 4x speedup compared to sequential execution."

**[VISUAL: Dashboard - performance metrics]**

**NARRATION:**
"The performance report shows excellent efficiency - 84% with 4 workers, demonstrating effective parallelization."

---

### PART 6: Database Integration & GraphQL (30 seconds)

**[VISUAL: Browser - GraphQL Playground at localhost:4000/graphql]**

**NARRATION:**
"All workflow executions are tracked in PostgreSQL and queryable via GraphQL."

**[VISUAL: Type and execute query]**

**QUERY:**
```graphql
query {
  workflowExecutions(limit: 5) {
    id
    workflowName
    status
    duration
    symbolExecutions {
      symbolName
      status
    }
  }
}
```

**[VISUAL: Show results]**

**NARRATION:**
"We can query execution history, compare baselines, and generate reports programmatically."

---

### CONCLUSION (30 seconds)

**[VISUAL: Return to terminal, show cleanup]**

**NARRATION:**
"That's WP Praxis - symbolic WordPress workflows with multi-language execution, distributed processing, and comprehensive auditing. Whether you're managing a single site or hundreds, WP Praxis provides the tools for declarative, traceable, and scalable WordPress operations."

**[VISUAL: Show project structure]**

**NARRATION:**
"Check out the tutorials and examples to get started. WP Praxis is open source under AGPL v3. Links in the description."

**[VISUAL: Fade to end card with links]**

**END CARD TEXT:**
- GitHub: github.com/wp-praxis/wp-praxis
- Documentation: /Docs
- Examples: /examples
- License: GNU AGPL v3

---

## Post-Recording Checklist

- [ ] Add title cards and transitions
- [ ] Add background music (if appropriate)
- [ ] Add annotations for key concepts
- [ ] Add chapter markers:
  - 0:00 - Introduction
  - 0:30 - Architecture Overview
  - 2:30 - Setup & First Workflow
  - 5:30 - Execute Workflow
  - 7:30 - View Results
  - 9:30 - Distributed Execution
  - 10:00 - Conclusion

- [ ] Export in multiple formats:
  - 4K (for YouTube)
  - 1080p (for general use)
  - 720p (for social media)

## Screenshots to Capture

1. Architecture diagram with all components highlighted
2. Docker Compose services running
3. Dashboard home page
4. Workflow YAML file (syntax highlighted)
5. Real-time execution progress
6. Visual diff report with charts
7. WordPress admin showing updated settings
8. 4 workers in swarm
9. Parallel execution visualization
10. GraphQL query results
11. Performance metrics chart

## Sound Bites for Social Media

1. "WordPress at scale through symbolic workflows" (15s)
2. "4x faster with distributed execution" (10s)
3. "Declarative workflows with automatic rollback" (12s)
4. "Multi-language execution: Rust, PHP, PowerShell, Elixir, TypeScript" (8s)

## Alternative Takes

### 5-Minute Version
- Skip architecture overview (show diagram only)
- Skip database/GraphQL section
- Focus on simple workflow + distributed execution

### 15-Minute Deep Dive
- Add custom symbol creation
- Show baseline comparison in detail
- Demonstrate rollback
- Show WordPress plugin UI
- Explain symbolic dispatch in detail

### 30-Second Teaser
- Show workflow execution only
- Highlight speed and visual diff
- Call to action: "Learn more at..."
