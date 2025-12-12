# streaktracker
A Claude-built, Gemini-mangled, Claude-corrected vibe-coded artifact/app to track activity streaks.

## what for
Use to, for example, track how many pushups you've done for how many days continuously. Or to count up an ever-lengthening period of abstinence from chocolate. Or to build a good habit such as meditating every day.

Streaks may be daily, weekly, or monthly. Weekly and monthly streaks can be set as, for example, once-per-week (ticks up if you did it that week) or once-before-seven-days-has-passed (new 7-day period starts once you record a streak-continuing activity)

Stores all streaks, ongoing ones and those that ended, with simple graphs for each. Data is stored locally so is device-specific but there is a copy-json-to-clipboard export and json import if you need to move the data around

## why do this
To track streaks. And to try vibe coding (utterly amateurishly) with Claude.

## what happened
Claude sought more details and we iterated over maybe ten versions, the last nine of which were polishing what was from the start pretty good. But the app didn't work in the iPhone Claude app but did on the Safari browser (and in Chrome on a PC). Thus began a journey:
* Tried using it for a day on the phone but login nags were pesky.
* Following a remark on Simon Willison's blog [https://simonwillison.net/2025/Dec/10/html-tools/#host-them-somewhere-else], decide to untether it from Claude's environment (away from nags like 'Download the free Claude app'). Simon also noted his prompts would include 'No React'.
* Claude rewrote the code but the artifact wouldn't perform in the artifact window and kept reporting code errors around line 700
* Deduced this was because I'm only using free-Claude so was running out of session time / tokens. But I've heard such good things about Gemini so maybe that can help...?
* Gemini didn't run out of time/tokens but kept borking the code, with event handling being beyond its skills. Frustrating. And in a loop: fixed one handler, next one failed; fixed the next, first one not working. Solution: learn to code. Solution 2: vibe with a better coder. Chose 2
* Went back to the conversation with free-Claude using a prompt that said, because we kept running out of session, I needed this done efficiently in one go. Which it did: one shot, half as many lines of html, all events handled.
