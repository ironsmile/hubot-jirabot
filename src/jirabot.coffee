# Description:
#   Looks up jira issues when they're mentioned in chat
#
#   Will ignore users set in HUBOT_JIRA_ISSUES_IGNORE_USERS (by default, JIRA and GitHub).
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_JIRA_URL (format: "https://jira-domain.com:9090")
#   HUBOT_JIRA_IGNORECASE (optional; default is "true")
#   HUBOT_JIRA_USERNAME (optional)
#   HUBOT_JIRA_PASSWORD (optional)
#   HUBOT_JIRA_ISSUES_IGNORE_USERS (optional, format: "user1|user2", default is "jira|github")
#
# Commands:
#
# Author:
#   hxnizamani

RegExp::execAll = (string) ->
  matches = []
  @lastIndex = 0
  while match = @exec string
    matches.push(match)
  return matches

module.exports = (robot) ->
  cache = []

  # In case someone upgrades form the previous version, we'll default to the
  # previous behavior.
  jiraUrl = process.env.HUBOT_JIRA_URL || "https://#{process.env.HUBOT_JIRA_DOMAIN}"
  jiraUsername = process.env.HUBOT_JIRA_USERNAME
  jiraPassword = process.env.HUBOT_JIRA_PASSWORD

  if jiraUsername != undefined && jiraUsername.length > 0
    auth = "#{jiraUsername}:#{jiraPassword}"

  jiraIgnoreUsers = process.env.HUBOT_JIRA_ISSUES_IGNORE_USERS
  if jiraIgnoreUsers == undefined
    jiraIgnoreUsers = "jira|github"

  robot.hear /.*\b(([A-Za-z]+)-[\d]+)\b.*/, (msg) ->
    # ignore if the user exists in 'jiraIgnoreUsers'
    return if msg.message.user.name.match(new RegExp(jiraIgnoreUsers, "gi"))

    matchAllRegexp = /\b(([A-Za-z]+)-[\d]+)\b/gi

    # used for filtering out duplicates
    alreadySent = []
    ticketToMatch = {}

    for match in matchAllRegexp.execAll(msg.message.text)
      ticket = match[1].toUpperCase()
      if alreadySent.indexOf(ticket) != -1
        continue
      alreadySent.push(ticket)
      ticketToMatch[ticket] = match

    # Make sure tickets are sent out in some logical order
    alreadySent.sort()

    for ticket in alreadySent
      msg.match = ticketToMatch[ticket]
      getIssues(msg)

  getIssues = (msg) ->
    try
      issue = msg.match[1].toUpperCase()
      now = new Date().getTime()
      if cache.length > 0
        cache.shift() until cache.length is 0 or cache[0].expires >= now

      # Fetching and posting Issue details via cache
      msg.send item.message for item in cache when item.issue is issue

      # If cache is empty or if the issue id does not exists in the cache, fetch via REST API
      if cache.length == 0 or (item for item in cache when item.issue is issue).length == 0
        robot.http(jiraUrl + "/rest/api/2/issue/" + issue)
          .auth(auth)
          .get() (err, res, body) ->
            try
              json = JSON.parse(body)
              key = json.key

              message = "[[" + key + "](" + jiraUrl + "/browse/" + key + ")] " + json.fields.summary
              message += '\nStatus: _'+json.fields.status.name+'_'

              if (json.fields.assignee == null)
                message += ', unassigned'
              else if ('value' of json.fields.assignee or 'displayName' of json.fields.assignee)
                if (json.fields.assignee.name == "assignee" and json.fields.assignee.value.displayName)
                  message += ', assigned to ' + json.fields.assignee.value.displayName
                else if (json.fields.assignee and json.fields.assignee.displayName)
                  message += ', assigned to ' + json.fields.assignee.displayName
              else
                message += ', unassigned'
              message += ", rep. by "+json.fields.reporter.displayName

              if json.fields.priority and json.fields.priority.name
                message += ', priority: ' + json.fields.priority.name

              msg.send message
              cache.push({issue: issue, expires: now + 120000, message: message})
            catch error
              try
                console.log("[*ERROR*] " + json.errorMessages[0])
              catch reallyError
                console.log("[*ERROR*] " + reallyError)
    catch error
      console.log("[*ERROR*] " + error)
