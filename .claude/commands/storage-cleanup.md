# Storage Cleanup Workflow

## Execution Instructions

When this command is invoked:

1. **Initialize Todo Tracking**
   - Create a todo list to track the cleanup process
   - Mark each phase as it progresses

2. **Baseline Disk Usage Analysis**
   - Run `df -h ~` to get current home directory disk usage
   - Record the starting point for comparison

3. **Comprehensive Storage Analysis**

   Analyze the following storage locations and report sizes:

   ### Docker Storage
   - Check if Docker is installed: `which docker`
   - If installed, analyze:
     - Docker images: `docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"`
     - Docker containers (all): `docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Size}}"`
     - Docker volumes: `docker volume ls -q | wc -l` and total size
     - Docker build cache: `docker system df`
     - Total reclaimable space: `docker system df -v`

   ### Package Manager Caches
   - **npm cache**: `du -sh ~/.npm 2>/dev/null`
   - **pnpm store**: `du -sh ~/.local/share/pnpm 2>/dev/null`
   - **yarn cache**: `du -sh ~/.yarn 2>/dev/null` and `du -sh ~/Library/Caches/Yarn 2>/dev/null`
   - **bun cache**: `du -sh ~/.bun/install/cache 2>/dev/null`

   ### Development Tool Caches
   - **Homebrew cache**: `du -sh ~/Library/Caches/Homebrew 2>/dev/null`
   - **Homebrew downloads**: `du -sh ~/Library/Caches/Homebrew/downloads 2>/dev/null`
   - **Xcode DerivedData**: `du -sh ~/Library/Developer/Xcode/DerivedData 2>/dev/null`
   - **Xcode Archives**: `du -sh ~/Library/Developer/Xcode/Archives 2>/dev/null`
   - **mise cache**: `du -sh ~/.local/share/mise 2>/dev/null`

   ### Application Caches
   - **Browser caches**:
     - Chrome: `du -sh ~/Library/Caches/Google/Chrome 2>/dev/null`
     - Safari: `du -sh ~/Library/Caches/Safari 2>/dev/null`
     - Arc: `du -sh ~/Library/Caches/company.thebrowser.Browser 2>/dev/null`
   - **Notion cache**: `du -sh ~/Library/Application\ Support/Notion 2>/dev/null`
   - **Slack cache**: `du -sh ~/Library/Application\ Support/Slack 2>/dev/null`
   - **VS Code cache**: `du -sh ~/Library/Application\ Support/Code 2>/dev/null`

   ### System Caches
   - **Top 20 largest subdirectories in ~/Library/Caches**:
     ```bash
     du -sh ~/Library/Caches/* 2>/dev/null | sort -hr | head -20
     ```
   - **Top 20 largest subdirectories in ~/Library/Application Support**:
     ```bash
     du -sh ~/Library/Application\ Support/* 2>/dev/null | sort -hr | head -20
     ```
   - **Top 20 largest subdirectories in ~/Library/Containers**:
     ```bash
     du -sh ~/Library/Containers/* 2>/dev/null | sort -hr | head -20
     ```

   ### Home Directory Analysis
   - **Top 20 largest directories in home**:
     ```bash
     du -sh ~/* 2>/dev/null | sort -hr | head -20
     ```

4. **Present Findings**

   Create a comprehensive report showing:
   - Total size for each category
   - Individual items with sizes
   - Estimated reclaimable space
   - Safety level for each cleanup operation:
     - SAFE: Can be cleaned without issues (caches that auto-rebuild)
     - MODERATE: Safe but may require re-downloading (package managers)
     - CAREFUL: Review before cleaning (application data)
     - DANGEROUS: Do not clean without explicit user confirmation

   Format the report in a clear, readable table or list format.

5. **Wait for User Decision**

   Ask the user which categories they want to clean. Present options as:
   - [ ] Docker (all: images, containers, volumes, build cache)
   - [ ] Docker (selective: only dangling images and stopped containers)
   - [ ] npm cache
   - [ ] pnpm store
   - [ ] yarn cache
   - [ ] Homebrew cache
   - [ ] Browser caches (specify which browsers)
   - [ ] Xcode DerivedData
   - [ ] Specific directories from the analysis
   - [ ] Custom cleanup (user specifies paths)

   **IMPORTANT**: Do NOT proceed with any cleanup until user explicitly confirms.

6. **Execute Cleanup**

   Based on user selection, execute appropriate cleanup commands:

   ### Docker Cleanup Commands
   - **Full cleanup**:
     ```bash
     docker system prune -a --volumes -f
     ```
   - **Selective cleanup** (safer):
     ```bash
     docker container prune -f
     docker image prune -a -f
     docker volume prune -f
     docker builder prune -f
     ```

   ### Package Manager Cleanup
   - **npm**: `npm cache clean --force`
   - **pnpm**: `pnpm store prune`
   - **yarn**: `yarn cache clean`
   - **Homebrew**: `brew cleanup -s`

   ### Application Caches
   - **Browser caches**: `rm -rf [specific cache directory]`
   - **Xcode DerivedData**: `rm -rf ~/Library/Developer/Xcode/DerivedData/*`

   ### Custom Paths
   - Confirm path with user before deletion
   - Use `rm -rf [path]` only after explicit confirmation

7. **Post-Cleanup Analysis**
   - Run `df -h ~` again to check final disk usage
   - Calculate space recovered
   - Report summary:
     - Starting disk usage
     - Ending disk usage
     - Total space recovered
     - List of operations performed

8. **Final Report**

   Provide a summary in this format:
   ```
   Storage Cleanup Summary
   =======================

   Before: [X.XX GB used]
   After:  [X.XX GB used]
   Recovered: [X.XX GB]

   Operations Performed:
   - [Operation 1]: [space recovered]
   - [Operation 2]: [space recovered]
   ...

   Recommendations:
   - [Any recommendations for future maintenance]
   ```

## Safety Guidelines

- **Always confirm before deleting**: Never execute destructive operations without explicit user confirmation
- **Provide context**: Explain what each cleanup operation does and its impact
- **Offer granular control**: Allow users to select specific items rather than forcing bulk operations
- **Check dependencies**: Warn if cleanup might affect running applications
- **Backup reminder**: For CAREFUL or DANGEROUS operations, remind users to backup if needed
- **Reversibility**: Clearly state which operations are reversible and which are not

## Command Patterns

Use Nushell syntax (`;` instead of `&&`):
```bash
# Good
command1; command2

# Avoid
command1 && command2
```

## Error Handling

- If a cleanup command fails, report the error but continue with remaining operations
- If Docker is not installed, skip Docker cleanup silently
- If a directory doesn't exist, skip it without error
- Always check command exit status before reporting success

## Notes

- This command requires sudo permissions for some system-level cleanups (ask before using sudo)
- Some applications may need to be quit before their caches can be cleaned
- Package manager caches will automatically rebuild when needed
- Docker cleanup will require re-downloading images when needed
- Browser caches cleanup may log users out of websites
