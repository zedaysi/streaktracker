# streaktracker
A Claude-build, Gemini-mangled, Claude-corrected vibe-coded artifact/app to track activity streaks.

Use to, for example, track how many pushups for how many days, or an ever-lengthening period of abstinence from chocolate, or to build a good habit such as meditating every day.
Stores all streaks, ongoing ones and those that ended. Shows simple graphs for each. Data is stored locally so is device-specific but there is a copy-json-to-clipboard export and json import if you need to move the data around

I did this to see first how easy it might be to get Claude to do it. Then, following a remark on Simon Willison's blog, I thought I should untether it from Claude's environment (away from pesky 'Download the app' nags and login requests) by converting the React code to html/javascript, hosting it on Github. Since I was only using free Claude, I kept running out of session time / tokens so switched to Gemini. That was illustrative: Gemini didn't run out of time/tokens but kept borking the code, with event handling being beyond its skills. So I went back to free-Claude with a prompt that I needed this done efficiently in one go... and it did, one shot, half as many lines of html, all events handled. Yet recently I've been hearing such good things about Gemini...
