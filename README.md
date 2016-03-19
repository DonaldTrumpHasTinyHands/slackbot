# PRINTFUL SLACK BOT

Post regular updates from your Printful store to your Slack channel of choice.

## Requirements

 * Ruby
 * A slack channel
 * A printful store
 * A job scheduler of some sort (we used CRON)

## Installation

 1. Install the application on your cron server
 2. Set up the env file to include the following variables:

````
SLACK_WEBHOOK=https://hooks.slack.com/services/some-secret-url
PRINTFUL_API=your-printful-api-hey
````

 3. Set it to run regularly using that job scheduler we talked about earlier
 4. Put your tiny hands together and say _excelllent_ in a sinster voice

![](https://pbs.twimg.com/media/CdmsyLqUUAAzcsy.jpg:large)
