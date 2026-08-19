# Decisions

Some initial key decisions regarding the SITAARA - Full Stack Assignment.

## Accounts

- The `child` is simply shared data, not an individual user profile
- Roles are enums `mom`, `dad` or `guardian`

## Video Progress Tracking

- Progress tracking can be inspired from khan academy.
- A series of checkpoints of sorts determine consumption of content.
- If a user chooses to skip to the end he still will be held to only the earliest pending checkpoint
- Prevents users from `cheating`

## Partner Linking

- We don't cater to the complexity involved on separation and unlinking of partners just yet (child ownership)
- If linking is mutual approval seems necessary but can be implemented in the future
- If after profile completion should 1 decide to link accounts, user initiating the link will be prompted to deleting their current child's data

## Progress Completion

- Can be shown on 2 levels
- Masterclass completion should strictly be video/no of videos
- Each chapter theoritically is equally important
- Each video can have a separate metric indicating percentage completed based of watch time
- Currently watching should only show up on an individual masterclass. Imagine on a scale of 100 masterclasses, visiting one video and marking most of them as in progress is misleading.
- `Only The most recently viewed masterclass within a period of 90 days is valid to be In Progress.`
