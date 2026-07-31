# Asymptome
CLI tracker to prioritize your limited time by ELO ranking media.

## Initial Ideas
- [ ] Mark books read/unread/in-progress.
- [ ] Show top 10 / bottom 10. Show only in-progress or unread.
- [ ] Rank only in-progress or unread.
- [ ] Track books by title, author, and series. Default is to recognize "by" or "(series)" and automatically sort into relevant fields.
  - [ ] But also almost nothing is actually *needed*.
- [x] Store progress as a numerical value? (Unread = 0, read = 1, in-progress in-between? Too easy to forget how it works?)
- [x] Store pages as an option,
  - [ ] allow a weighted priority based on remaining percentage or whatever.
- [ ] Store items as an array instead of object, because that makes the JSON output more consistent -> smaller JSON commit differences.

## data structure of an item
```json
{
  title = "Title",
  author = "Author",
  series = "Series",
  pages = 100,
  priority = 0,
  progress = 0.5,
}
```

- `title`, `author`, `series`, and `pages` are optional.
- At least one of `title`, `author`, or `series` must be defined.
- `priority` is the ELO ranking, initializing to `0`.
- `progress` represents read/unread/in-progress status. `0` is unread, `1` is read, and anything in-between in a percentage of progress.

## the name
A combination of asymptote - because you will die before you finish your reading list, always getting closer but never arriving - and tome.
