# 1. Restart pdk nightly on acceptance test failures

Date: 2024-04-22

## Status

Accepted

## Context

Over the last several months, the pdk's `nightly` "acceptance" test has intermittently failed with an error like the ['nightly' result](https://github.com/puppetlabs/pdk/actions/runs/8768725070/job/24063420981) below.  An error like this occurs sometimes over a couple evenings and then disappears for many weeks.  Re-running the `nightly` workflow corrects these errors, which suggests that the root cause is probably something in the local github runner environment.  As a result of these intermittant failures, I began **investigating a way to automatically retry the failing workflow**.

```ruby
Failures:

  1) pdk set config when run outside of a module with an invalid type Command "pdk set config --type invalid_type_name user.module_defaults.mock value" behaves like a saved JSON configuration file saves the setting
     Failure/Error: expect(File).to exist(ENV.fetch('PDK_ANSWER_FILE', nil))
       expected File to exist
       Dumping stderr output:
       
       pdk (ERROR): Unknown type invalid_type_name. Expected one of 'array', 'boolean', 'number', 'string'
       
     Shared Example Group: "a saved JSON configuration file" called from ./spec/acceptance/set_config_spec.rb:138
     # ./spec/acceptance/set_config_spec.rb:22:in `block (3 levels) in <top (required)>'
     # ./spec/acceptance/support/with_a_fake_tty.rb:4:in `block (2 levels) in <top (required)>'
```

Although github has an out-of-the box action feature for retrying a step; it does not have for retrying an entire workflow.  The reason for this is probably to prevent accidental workflow retry loops.  Fortunately, automatically re-triggering a workflow is possible and the key to the solution is to separate the first failing workflow process from the second workflow that retriggers the first.

One way to separate the workflows is to have a second workflow "listen" and then peform corrective action on the first.  For example, the `workflow-restarter` workflow could listen for `nightly` workflow completion events and then restart the `nightly` if it fails.  I ruled out this option because although it worked, the listener ended up cluttering the Action tab with lots of irrelevant entries: the listener not only triggered when the `nightly` failed but also when it succeeded.

Another way to separate the workflows is to use the `workflow_dispatch` API.  In effect, using the API looks something like `nightly ==API workflow dispatch event==> workflow-restarter ==API workflow dispatch event==> nightly`.  This proved to be the cleanest way of doing things.

## Decision

Therefore, I decided to use the workflow_dispatch API and create some `workflow-restarter` re-usable code (custom action, re-usable workflow, and a test worklow).  For more information see usage instruction here [.github/actions/workflow-restarter-proxy/README](https://github.com/puppetlabs/pdk/tree/96169568bf84c570343c6644a75f7713ff3e7dcb/.github/actions/workflow-restarter-proxy) and [this PR](https://github.com/puppetlabs/pdk/pull/1344).

## Consequences

The `workflow-restarter` has several advantages:

* it can be easily re-used by other workflows in this repository.  Since the code has been extracted into a custom action and re-usable workflow, it is easy to add the `on-failure-workflow-restarter` to other workflows.
* it only adds entries to the github action tab when there's a failure.  This means it's easy to check the action history to see if there've been any restart events.
* it is configurable.  The number of retries is by default 3; however, this value is configurable.

One potential disadvantage of this solution, however, is that the `workflow-restarter` isn't available for re-use in other repositories.  If the `workflow-restarter` proves to be useful for the PDK, then we should investigate how to move this into a common location like [puppetlabs/cat-github-actions](https://github.com/puppetlabs/cat-github-actions/tree/main).
