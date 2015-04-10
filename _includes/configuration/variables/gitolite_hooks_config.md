#### Gitolite Hooks Config
***

Setting | Default | Notes
--------|---------|------
**:gitolite_hooks_are_asynchronous**   | `true`  | Execute Gitolite hooks in background. No output will be display on console.
**:gitolite_overwrite_existing_hooks** | `true`  | Force Gitolite hooks update. This install our provided hooks (those in ```contrib/hooks```) in Gitolite.
**:gitolite_hooks_debug**              | `false` | Execute Gitolite hooks in debug mode.
**:gitolite_hooks_url**                | `http://localhost:3000` | The Redmine url. This should point to your Redmine instance.
