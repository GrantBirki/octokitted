# GitHub Events

This fixture directory contains **live** GitHub events. These are files that contain all sorts of rich information about the event that occurred which triggered a GitHub Action run.

[Default Actions Variables](https://docs.github.com/en/actions/learn-github-actions/variables#default-environment-variables)

[GitHub Events Documentation](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows)

## Note

I have noticed that the `push` workflow will override the `on: pull_request` event if the `push` trigger doesn't have any branches associated with it. This is actually really annoying as the `push` event takes precedence over the `pull_request` event and the `push` event doesn't have any of the `pull_request` event information. To prevent this, I have added a `branches` key to the `push` event that is empty. This will prevent the `push` event from overriding the `pull_request` event.

In this directory, here are two examples of each as described above:

- [`commit_pushed.json`](commit_pushed.json) - This is a `push` event that has a `branches` key that is empty. Notice how it has absolutely zero pull request information (oof)
- [`commit_on_pull_request.json`](commit_on_pull_request.json) - This is a `pull_request` event that has a `push` event that has a `branches` key that is empty. Notice how it has all the pull request information (yay)
