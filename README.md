# Claude Code Plugin Marketplace on GitHub

A step-by-step guide to publishing Claude Code plugins from your own GitHub repository and installing them via a self-hosted marketplace — including versioning, private repos, and multi-user access.

## Create and Clone an Empty Public GitHub Repository

```bash
    git clone https://github.com/<your-github-account>/bvh-ccps.git
    cd bvh-ccps
```

## 1. Create the Marketplace Plugin Structure

Below is an example of how to structure your repository. The [`marketplace.json`](.claude-plugin/marketplace.json) file is required and should be placed in the `.claude-plugin` directory at the root of your repository.

Each plugin should have its own directory under `plugins/`, and each plugin should have its own [`.claude-plugin/plugin.json`](plugins/bvh-ccp/.claude-plugin/plugin.json) file and a `skills/` directory containing the skill markdown files.

```text
    bvh-ccps/
    ├── .claude-plugin/
    │   └── marketplace.json
    └── plugins/
        └── bvh-ccp/
            ├── .claude-plugin/
            │   └── plugin.json
            └── skills/
                ├── hello-world/
                │   └── SKILL.md
                └── another-one/
                    └── SKILL.md
```

This repository itself follows the structure above. You will definitely need to change the folder names, the content of the `marketplace.json`, `plugin.json` and skills to reflect your own plugin and skills.

## 2. Push Your Changes to GitHub

```bash
    git add .
    git commit -m "Add marketplace plugin structure"
    git push origin main
```

## 3. Install Plugin from Your Marketplace

1. Add your marketplace (run inside a Claude Code session):

   ```text
       /plugin marketplace add <your-github-account>/bvh-ccps
   ```

   This clones your GitHub repo and reads .claude-plugin/marketplace.json, registering the catalog — nothing gets installed yet.

2. Install the plugin from it:

   ```text
       /plugin install bvh-ccp@bvh-ccps
   ```

   The **@bvh-ccps** is the marketplace name (from name in marketplace.json), and **bvh-ccp** is the plugin name (from name in plugin.json).

3. Activate it:

   ```text
       /reload-plugins
   ```

   Skills are namespaced by plugin name, so you'd then invoke them as:

   ```text
       /bvh-ccp:hello-world
   ```

## 4. Bump Version to Refresh Plugin after Pushing Changes

Pushing changes to the GitHub repository does not automatically refresh an already-installed plugin on your machine.

> [!WARNING]
> Running `/plugin marketplace update bvh-ccps` and `/reload-plugins` alone does not refresh an installed plugin.

The issue is that Claude Code only re-syncs an installed plugin's cache when the version field changes — marketplace update just refreshes the catalog of what's available, it doesn't force-refresh already-installed plugins at an unchanged version.

Fix: bump "version" in plugins/bvh-ccp/.claude-plugin/plugin.json (e.g. 1.0.0 → 1.0.1) every time you push skill changes, then push again (Step 2) and run `/plugin marketplace update` + `/reload-plugins` to refresh. That's the supported workflow for iterating on a plugin.

To do this automatically, you can create a GitHub Action named [**bump-version.yml**](.github/workflows/bump-version.yml) to bump the version on every push to main:

```yaml
name: Bump plugin version

on:
  push:
    branches: [main]
    paths:
      - "plugins/bvh-ccp/**"

permissions:
  contents: write

jobs:
  bump-version:
    if: "!contains(github.event.head_commit.message, '[skip version]')"
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Bump patch version
        id: bump
        run: |
          FILE=plugins/bvh-ccp/.claude-plugin/plugin.json
          VERSION=$(jq -r .version "$FILE")
          IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"
          NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))"
          jq --arg v "$NEW_VERSION" '.version = $v' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
          echo "new_version=$NEW_VERSION" >> "$GITHUB_OUTPUT"

      - name: Commit and push
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add plugins/bvh-ccp/.claude-plugin/plugin.json
          git commit -m "chore: bump plugin version to ${{ steps.bump.outputs.new_version }} [skip version]"
          git push
```

One-time setup needed on GitHub (so the bot can push):
Repo → Settings → Actions → General → Workflow permissions → set to "Read and write permissions".

Now every time a skill has changed and you push to main, the version in plugin.json will auto-increment. After the Action runs, refresh locally:

```text
    /plugin marketplace update bvh-ccps
    /reload-plugins
```

> [!WARNING]
> Be mindful that this workflow action will create a new commit on every time it runs.
> Your local repository will be out of sync with the remote after this run, so you will need to pull the changes before pushing new changes:

```bash
    git pull origin main
    # resolve any merge conflicts if necessary
    git add .
    git commit -m "Your commit message"
    git push origin main
```

## 5. Set Up Private Repository Access

Claude Code can add a marketplace from a private GitHub repo, but it needs Git access to clone it first:

1. Make the repository private on GitHub, and make sure `.claude-plugin/marketplace.json` lives at the repo root on the default branch.
2. Open a terminal and install the GitHub CLI (`winget install GitHub.cli`).
3. Authenticate — when prompted, also choose to authenticate Git with your GitHub credentials, so `git clone` works for the private repo over HTTPS:

   ```bash
       gh auth login
   ```

4. Now you can update the marketplace in Claude Code as before, using the same command but with your private repo

   ```text
       /plugin marketplace update bvh-ccps
       /reload-plugins
   ```

## 6. Add Other Users

Other users don't need your GitHub credentials — they authenticate with their own GitHub account, and you just grant that account access to the private repo.

1. Give each user access to the repository:
   - **A few users:** GitHub → repo → Settings → Collaborators → Add people, and invite their GitHub username or email.
   - **Many users:** Move the repo into a GitHub Organization, create a Team, and add users to it with read access to the repo.
2. Each user installs the GitHub CLI and authenticates with their own account:

   ```bash
       gh auth login
   ```

3. Once they've accepted the invite and authenticated, they follow the same steps in the "Install Plugin from Your Marketplace" section above — using their own GitHub account, not yours.

A shared, read-only Personal Access Token is an alternative to collaborator invites, but it's still a secret you'd need to distribute and rotate — granting access per-account is cleaner for ongoing use.
