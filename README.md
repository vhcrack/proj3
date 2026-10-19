# Project 3 - *BeReal Clone*

Submitted by: **vhcrack (real name censored for privacy)**

**BeReal Clone** is an app that is a clone of BeReal, mimicing similar functionality.

Time spent: **3** hours spent in total

## Required Features

The following **required** functionality is completed:

- [x] User can launch camera to take photo instead of photo library
  - [x] Users without iPhones to demo this feature can manually add unique photos to their simulator’s Photos app
- [x] Posts have a time and location attached to them
- [x] Users are not able to see other users’ photos until they upload their own.

The following **optional** features are implemented:

- [ ] Posts have a comment section, which displays the commenter’s username and comment context
- [ ] User receives notification when it is time to post

The following **additional** features are implemented:

- [ ] List anything else that you can get done to improve the app functionality!

## Video Walkthrough

[Video Walkthrough](https://www.youtube.com/watch?v=p6TVSd6YtKs).

## Notes

The biggest issue I had while building the app was fixing the functionality of usernames appearing on posts, unfortunately I had encountered an issue where usernames would revert to placeholders or be entirely blank. I ended up having to add a new column to the _Post class and make the act of posting itself add a display name associated with the post to fix the issue, which took a while.

## License

    Copyright [2026] [vhcrack (real name censored for privacy)]

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
