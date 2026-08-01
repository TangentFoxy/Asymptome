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

I think the opening UI should be to display the top 10 books in-progress (sort order customizable by user), where pressing a number key
allows the user to immediately enter an updated progress. Additional alphabetic keys are an option to access other features. This way
tracker use is near frictionless. (0 maps to 10)

## Contributions

This repo is hosted at https://gitea.tangentfox.com/tangent/Asymtome and
force-pushed to https://github.com/TangentFoxy/Asymtome when commits are made.
I accept pull requests and issues, but management of the code is handled there.

Licensing? I don't care. Do whatever you want. IP rights are stupid.

## Book Data Structure
```json
{
  "title": "Title",
  "author": "Author",
  "series": "Series",
  "pages": 100,
  "priority": 0,
  "progress": 0.5,
  "hidden": true
}
```

- `title`, `author`, `series`, `pages`, and `hidden` are optional.
- At least one of `title`, `author`, or `series` must be defined.
- `priority` is the ELO ranking, initializing to `0`.
- `progress` represents read/unread/in-progress status. `0` is unread, `1` is
  read, and anything in-between in a percentage of progress.
- `hidden` is undefined or `true` to hide a book from ALL of the interface
  without deleting its data.

## Why "Asymptome" ?
A combination of asymptote - because you will die before you finish your reading
list, always getting closer but never arriving - and tome.

It's also a-symptom of my neuroses. :D
