[![npm](https://badge.fury.io/js/hubot-jirabot-ng.svg)](https://www.npmjs.com/package/hubot-jirabot-ng)

# hubot-jirabot-ng

A hubot script to expand JIRA tickets from their keys. Whenever the bot hears something which
looks like a JIRA issue (e.g. PROJECT-84123) it would check in JIRA and expand it in. Example:

> john: Have seen PROJECT-84123?
> hubot: [PROJECT-84123] The main database server is down, migrate to replicas
> Status: To Do, assigned to John Harvee, rep. by Support team, fixVersion: NONE, priority: Major
> https://jira-domain.com/browse/PROJECT-84123

See [`src/jirabot.coffee`](src/jirabot.coffee) for full documentation.

## Fork

This is a fork of the [hubot-jirabot](https://github.com/agiledigital/hubot-jirabot). But this fork has some improvements over the upstream. Mainly,
it would extract and show you all the JIRA tickets which are found in a message. Not just one of them.

## Installation

In hubot project repo, run:

`npm install hubot-jirabot-ng --save`

Then add **hubot-jirabot-ng** to your `external-scripts.json`:

```json
["hubot-jirabot-ng"]
```

## Usage

This plugin requires some environment variables in order to work. They are

```
HUBOT_JIRA_URL (format: "https://jira-domain.com:9090")
HUBOT_JIRA_IGNORECASE (optional; default is "true")
HUBOT_JIRA_USERNAME (optional)
HUBOT_JIRA_PASSWORD (optional)
HUBOT_JIRA_ISSUES_IGNORE_USERS (optional, format: "user1|user2", default is "jira|github")
```
